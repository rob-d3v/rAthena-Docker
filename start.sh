#!/bin/bash

cd /home/rathena/rAthena

# Verificar se precisamos configurar o banco de dados
if [ ! -f ".db_configured" ]; then
  echo "Aguardando o serviço do MySQL iniciar..."
  MYSQL_HOST=${MYSQL_HOST:-"db"}
  MYSQL_PORT=${MYSQL_PORT:-"3306"}
  MYSQL_USER=${MYSQL_USER:-"ragnarok"}
  MYSQL_PASS=${MYSQL_PASS:-"ragnarok"}
  MYSQL_DB=${MYSQL_DB:-"ragnarok"}
  
  # Copiar os arquivos de configuração
  echo "Verificando arquivos de configuração..."
  for conf_example in $(find ./conf -name "*.conf.example" 2>/dev/null); do
    conf_file="${conf_example%.example}"
    if [ ! -f "$conf_file" ]; then
      echo "Copiando $conf_example para $conf_file"
      cp "$conf_example" "$conf_file"
    fi
  done
  
  # Verificar se a pasta import existe
  if [ ! -d "./conf/import" ]; then
    mkdir -p ./conf/import
    if [ -d "./conf/import-tmpl" ]; then
      cp ./conf/import-tmpl/* ./conf/import/ 2>/dev/null || true
    fi
  fi
  
  # Aguardar o MySQL ficar disponível
  until mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1"; do
    echo "Aguardando MySQL em $MYSQL_HOST:$MYSQL_PORT..."
    sleep 5
  done
  
  # Verificar e reparar tabelas corrompidas (se existirem)
  echo "Verificando tabelas existentes..."
  mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "REPAIR TABLE ragnarok.login, ragnarok.loginlog" || true
  
  # Configurar conexão com banco de dados
  if [ -f "conf/inter_athena.conf" ]; then
    echo "Configurando conexão com o banco de dados..."
    sed -i "s/127.0.0.1/$MYSQL_HOST/g" conf/inter_athena.conf
    
    # Configurações de IP/porta/etc
    # [Manter seu código original aqui]
  fi
  
  # Configurar login_athena.conf
  if [ -f "conf/login_athena.conf" ]; then
    echo "Configurando login_athena.conf..."
    # Certificar-se de que o login server está ouvindo em todas as interfaces
    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/login_athena.conf
  fi
  
  # Configurar char_athena.conf
  if [ -f "conf/char_athena.conf" ]; then
    echo "Configurando char_athena.conf..."
    # Configurar o IP do login server para o próprio contêiner
    sed -i "s/^login_ip: .*$/login_ip: 127.0.0.1/" conf/char_athena.conf
    # Certificar-se de que o char server está ouvindo em todas as interfaces
    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/char_athena.conf
  fi
  
  # Configurar map_athena.conf
  if [ -f "conf/map_athena.conf" ]; then
    echo "Configurando map_athena.conf..."
    # Configurar o IP do char server para o próprio contêiner
    sed -i "s/^char_ip: .*$/char_ip: 127.0.0.1/" conf/map_athena.conf
    # Certificar-se de que o map server está ouvindo em todas as interfaces
    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/map_athena.conf
  fi
  
  # Criar as tabelas no banco de dados (ignorando erros de duplicidade)
  echo "Criando tabelas no banco de dados..."
  # Primeiro, criar o banco de dados se ainda não existir
  mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
  
  # Importar os arquivos SQL com opção para ignorar erros
  for sql_file in sql-files/*.sql; do
    echo "Importando $sql_file..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" < "$sql_file" || true
  done
  
  touch .db_configured
fi

# Iniciar servidores com retry e backoff
max_retries=5
retry_count=0
retry_delay=5

echo "Iniciando os servidores rAthena..."

# Iniciar login-server com retry
while [ $retry_count -lt $max_retries ]; do
  echo "Tentativa $(($retry_count + 1))/$max_retries de iniciar o login-server..."
  ./login-server > ./log/login-server.log 2>&1 &
  LOGINPID=$!
  echo "Login server PID: $LOGINPID"
  sleep 3
  
  # Verificar se o processo existe e está rodando
  if kill -0 $LOGINPID 2>/dev/null; then
    echo "Login server iniciado com sucesso!"
    break
  else
    echo "Login server falhou, tentando novamente em $retry_delay segundos..."
    retry_count=$((retry_count + 1))
    sleep $retry_delay
    retry_delay=$((retry_delay * 2))  # Aumenta o tempo de espera exponencialmente
  fi
done

if [ $retry_count -eq $max_retries ]; then
  echo "ERRO FATAL: Não foi possível iniciar o login-server após $max_retries tentativas."
  cat ./log/login-server.log
  exit 1
fi

# Resetar contadores para o char-server
retry_count=0
retry_delay=5

# Iniciar char-server com retry
while [ $retry_count -lt $max_retries ]; do
  echo "Tentativa $(($retry_count + 1))/$max_retries de iniciar o char-server..."
  ./char-server > ./log/char-server.log 2>&1 &
  CHARPID=$!
  echo "Char server PID: $CHARPID"
  sleep 3
  
  # Verificar se o processo existe e está rodando
  if kill -0 $CHARPID 2>/dev/null; then
    echo "Char server iniciado com sucesso!"
    break
  else
    echo "Char server falhou, tentando novamente em $retry_delay segundos..."
    retry_count=$((retry_count + 1))
    sleep $retry_delay
    retry_delay=$((retry_delay * 2))
  fi
done

if [ $retry_count -eq $max_retries ]; then
  echo "ERRO FATAL: Não foi possível iniciar o char-server após $max_retries tentativas."
  cat ./log/char-server.log
  exit 1
fi

# Resetar contadores para o map-server
retry_count=0
retry_delay=5

# Iniciar map-server com retry
while [ $retry_count -lt $max_retries ]; do
  echo "Tentativa $(($retry_count + 1))/$max_retries de iniciar o map-server..."
  ./map-server > ./log/map-server.log 2>&1 &
  MAPPID=$!
  echo "Map server PID: $MAPPID"
  sleep 3
  
  # Verificar se o processo existe e está rodando
  if kill -0 $MAPPID 2>/dev/null; then
    echo "Map server iniciado com sucesso!"
    break
  else
    echo "Map server falhou, tentando novamente em $retry_delay segundos..."
    retry_count=$((retry_count + 1))
    sleep $retry_delay
    retry_delay=$((retry_delay * 2))
  fi
done

if [ $retry_count -eq $max_retries ]; then
  echo "ERRO FATAL: Não foi possível iniciar o map-server após $max_retries tentativas."
  cat ./log/map-server.log
  exit 1
fi

# Iniciar web-server (se disponível)
if [ -f ./web-server ]; then
  echo "Iniciando web-server..."
  ./web-server > ./log/web-server.log 2>&1 &
  WEBPID=$!
  echo "Web server PID: $WEBPID"
fi

echo "Todos os servidores foram iniciados. Logs disponíveis em ./log/"
echo "Pressione Ctrl+C para encerrar."
echo "PIDs: Login=$LOGINPID, Char=$CHARPID, Map=$MAPPID"

# Monitorar os servidores
while true; do
  # Verificar se os processos ainda estão rodando
  if ! kill -0 $LOGINPID 2>/dev/null; then
    echo "ALERTA: Login server não está mais rodando!"
  fi
  
  if ! kill -0 $CHARPID 2>/dev/null; then
    echo "ALERTA: Char server não está mais rodando!"
  fi
  
  if ! kill -0 $MAPPID 2>/dev/null; then
    echo "ALERTA: Map server não está mais rodando!"
  fi
  
  sleep 30
done