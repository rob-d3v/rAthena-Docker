#!/bin/bash

cd /home/rathena/rAthena

# Verificar se precisamos configurar o banco de dados
if [ ! -f ".db_configured" ]; then
  echo "Aguardando o serviço do MySQL iniciar..."
  # Substitua os valores abaixo pelos seus próprios valores
  MYSQL_HOST=${MYSQL_HOST:-"db"}
  MYSQL_PORT=${MYSQL_PORT:-"3306"}
  MYSQL_USER=${MYSQL_USER:-"ragnarok"}
  MYSQL_PASS=${MYSQL_PASS:-"ragnarok"}
  MYSQL_DB=${MYSQL_DB:-"ragnarok"}
  
  # Copiar os arquivos de configuração padrão se não existirem
  if [ ! -d "./conf" ]; then
    mkdir -p ./conf
  fi
  
  # Verificar se existem arquivos .conf.example e copiá-los para .conf se necessário
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
    # Copiar arquivos da pasta import-tmpl se existir
    if [ -d "./conf/import-tmpl" ]; then
      cp ./conf/import-tmpl/* ./conf/import/ 2>/dev/null || true
    fi
  fi
  
  # Aguardar o MySQL ficar disponível
  until mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1"; do
    echo "Aguardando MySQL em $MYSQL_HOST:$MYSQL_PORT..."
    sleep 5
  done
  
  # Configurar conexão com banco de dados
  if [ -f "conf/inter_athena.conf" ]; then
    echo "Configurando conexão com o banco de dados..."
    sed -i "s/127.0.0.1/$MYSQL_HOST/g" conf/inter_athena.conf
    
    # Verifique se login_server_ip existe no arquivo
    if grep -q "login_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^login_server_ip: .*$/login_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^login_server_port: .*$/login_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^login_server_id: .*$/login_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^login_server_pw: .*$/login_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^login_server_db: .*$/login_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Verifique se char_server_ip existe no arquivo
    if grep -q "char_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^char_server_ip: .*$/char_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^char_server_port: .*$/char_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^char_server_id: .*$/char_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^char_server_pw: .*$/char_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^char_server_db: .*$/char_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Verifique se map_server_ip existe no arquivo
    if grep -q "map_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^map_server_ip: .*$/map_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^map_server_port: .*$/map_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^map_server_id: .*$/map_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^map_server_pw: .*$/map_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^map_server_db: .*$/map_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Verifique se log_db_ip existe no arquivo
    if grep -q "log_db_ip:" conf/inter_athena.conf; then
      sed -i "s/^log_db_ip: .*$/log_db_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^log_db_port: .*$/log_db_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^log_db_id: .*$/log_db_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^log_db_pw: .*$/log_db_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^log_db_db: .*$/log_db_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Verifique se web_server_ip existe no arquivo
    if grep -q "web_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^web_server_ip: .*$/web_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^web_server_port: .*$/web_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^web_server_id: .*$/web_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^web_server_pw: .*$/web_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^web_server_db: .*$/web_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
  else
    echo "Arquivo conf/inter_athena.conf não encontrado!"
  fi
  
  # Criar as tabelas no banco de dados
  for sql_file in sql-files/*.sql; do
    echo "Importando $sql_file..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" < "$sql_file"
  done
  
  touch .db_configured
fi

# Iniciar os servidores usando screen
echo "Iniciando os servidores rAthena..."
# Método 1: Usando o script oficial
# ./athena-start start

# Método 2: Iniciando os servidores manualmente
# Apenas para fins de demonstração, vamos iniciar os servidores em primeiro plano
# Em produção, você provavelmente usaria o script athena-start ou o screen

# Iniciar login-server
echo "Iniciando login-server..."
./login-server &
sleep 2

# Iniciar char-server
echo "Iniciando char-server..."
./char-server &
sleep 2

# Iniciar map-server
echo "Iniciando map-server..."
./map-server &
sleep 2

# Iniciar web-server (se disponível)
if [ -f ./web-server ]; then
  echo "Iniciando web-server..."
  ./web-server &
fi

# Manter o container rodando
echo "Todos os servidores foram iniciados. Pressione Ctrl+C para sair."
tail -f /dev/null