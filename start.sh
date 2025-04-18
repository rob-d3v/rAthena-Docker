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
  
  # Aguardar o MySQL ficar disponível com retry
  MAX_RETRY=30
  RETRY=0
  until mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1" >/dev/null 2>&1; do
    RETRY=$((RETRY+1))
    if [ $RETRY -ge $MAX_RETRY ]; then
      echo "Falha ao conectar ao MySQL após $MAX_RETRY tentativas. Verifique se o servidor MySQL está em execução."
      exit 1
    fi
    echo "Aguardando MySQL em $MYSQL_HOST:$MYSQL_PORT... (tentativa $RETRY/$MAX_RETRY)"
    sleep 5
  done
  echo "Conexão com MySQL estabelecida com sucesso!"
  
  # Verificar se o banco de dados existe, criar se não existir
  DB_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES LIKE '$MYSQL_DB';" 2>/dev/null | grep -c "$MYSQL_DB")
  if [ "$DB_EXISTS" -eq 0 ]; then
    echo "Criando banco de dados $MYSQL_DB..."
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE $MYSQL_DB;" 2>/dev/null
  fi
  
  # Verificar e reparar tabelas existentes
  echo "Verificando tabelas existentes..."
  mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = '$MYSQL_DB';" 2>/dev/null | grep -v "table_name" | while read -r table; do
    if [ ! -z "$table" ]; then
      echo "Verificando tabela: $table"
      mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "REPAIR TABLE \`$table\`;" 2>/dev/null
    fi
  done
  
  # Configurar conexão com banco de dados
  if [ -f "conf/inter_athena.conf" ]; then
    echo "Configurando conexão com o banco de dados..."
    sed -i "s/127.0.0.1/$MYSQL_HOST/g" conf/inter_athena.conf
    
    # Configurar login_server_ip
    if grep -q "login_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^login_server_ip: .*$/login_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^login_server_port: .*$/login_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^login_server_id: .*$/login_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^login_server_pw: .*$/login_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^login_server_db: .*$/login_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Configurar char_server_ip
    if grep -q "char_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^char_server_ip: .*$/char_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^char_server_port: .*$/char_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^char_server_id: .*$/char_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^char_server_pw: .*$/char_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^char_server_db: .*$/char_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Configurar map_server_ip
    if grep -q "map_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^map_server_ip: .*$/map_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^map_server_port: .*$/map_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^map_server_id: .*$/map_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^map_server_pw: .*$/map_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^map_server_db: .*$/map_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Configurar log_db_ip
    if grep -q "log_db_ip:" conf/inter_athena.conf; then
      sed -i "s/^log_db_ip: .*$/log_db_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^log_db_port: .*$/log_db_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^log_db_id: .*$/log_db_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^log_db_pw: .*$/log_db_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^log_db_db: .*$/log_db_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
    
    # Configurar web_server_ip
    if grep -q "web_server_ip:" conf/inter_athena.conf; then
      sed -i "s/^web_server_ip: .*$/web_server_ip: $MYSQL_HOST/" conf/inter_athena.conf
      sed -i "s/^web_server_port: .*$/web_server_port: $MYSQL_PORT/" conf/inter_athena.conf
      sed -i "s/^web_server_id: .*$/web_server_id: $MYSQL_USER/" conf/inter_athena.conf
      sed -i "s/^web_server_pw: .*$/web_server_pw: $MYSQL_PASS/" conf/inter_athena.conf
      sed -i "s/^web_server_db: .*$/web_server_db: $MYSQL_DB/" conf/inter_athena.conf
    fi
  fi
  
  # Configurar login_athena.conf
  if [ -f "conf/login_athena.conf" ]; then
    echo "Configurando login_athena.conf..."
    # Certificar-se de que o login server está ouvindo em todas as interfaces
    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/login_athena.conf
    
    # Adicionar opções de segurança
    if ! grep -q "ipban_enable:" conf/login_athena.conf; then
      echo "ipban_enable: yes" >> conf/login_athena.conf
    else
      sed -i "s/^ipban_enable: .*$/ipban_enable: yes/" conf/login_athena.conf
    fi
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
  
  # Criar as tabelas no banco de dados
  echo "Criando tabelas no banco de dados..."
  for sql_file in sql-files/*.sql; do
    echo "Importando $sql_file..."
    # Usar o parâmetro --force para ignorar erros durante a importação
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" --force < "$sql_file" || true
  done
  
  touch .db_configured
fi

# Adicionando verificação de integridade do banco de dados
if [ "${AUTO_REPAIR_DB:-"true"}" = "true" ]; then
  echo "Verificando integridade do banco de dados..."
  mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "
    USE $MYSQL_DB;
    SELECT TABLE_NAME, ENGINE, TABLE_ROWS 
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = '$MYSQL_DB' 
    ORDER BY TABLE_NAME;" 2>/dev/null

  # Verificar e reparar tabelas corrompidas
  echo "Verificando e reparando tabelas automaticamente..."
  TABLES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -N -e "
    SELECT TABLE_NAME FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = '$MYSQL_DB';" 2>/dev/null)
  
  for TABLE in $TABLES; do
    echo "Verificando tabela: $TABLE"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "CHECK TABLE \`$TABLE\`;" 2>/dev/null
    
    # Repara automaticamente se encontrar problemas
    HAS_ISSUE=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "CHECK TABLE \`$TABLE\`;" 2>/dev/null | grep -E "error|warning|crashed" | wc -l)
    if [ $HAS_ISSUE -gt 0 ]; then
      echo "Reparando tabela $TABLE..."
      mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "REPAIR TABLE \`$TABLE\`;" 2>/dev/null
    fi
  done
fi

# Verifica se o diretório de log existe
if [ ! -d "./log" ]; then
  mkdir -p ./log
fi

# Criar o script de verificação de servidores se não existir
if [ ! -f "/home/rathena/scripts/check_servers.sh" ]; then
  mkdir -p /home/rathena/scripts
  cat > /home/rathena/scripts/check_servers.sh << 'EOF'
#!/bin/bash

# Variáveis do banco de dados
MYSQL_HOST=${MYSQL_HOST:-"db"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_USER=${MYSQL_USER:-"ragnarok"}
MYSQL_PASS=${MYSQL_PASS:-"ragnarok"}
MYSQL_DB=${MYSQL_DB:-"ragnarok"}

# Verificar se os servidores estão rodando
LOGIN_RUNNING=$(ps aux | grep login-server | grep -v grep | wc -l)
CHAR_RUNNING=$(ps aux | grep char-server | grep -v grep | wc -l)
MAP_RUNNING=$(ps aux | grep map-server | grep -v grep | wc -l)

if [ $LOGIN_RUNNING -eq 0 ] || [ $CHAR_RUNNING -eq 0 ] || [ $MAP_RUNNING -eq 0 ]; then
  echo "$(date) - Um ou mais servidores não estão rodando. Tentando reiniciar..."
  
  # Tenta reiniciar os serviços que não estão rodando
  if [ $LOGIN_RUNNING -eq 0 ]; then
    cd /home/rathena/rAthena
    ./login-server > ./log/login-server.log 2>&1 &
    echo "$(date) - Login server reiniciado"
  fi
  
  if [ $CHAR_RUNNING -eq 0 ]; then
    cd /home/rathena/rAthena
    ./char-server > ./log/char-server.log 2>&1 &
    echo "$(date) - Char server reiniciado"
  fi
  
  if [ $MAP_RUNNING -eq 0 ]; then
    cd /home/rathena/rAthena
    ./map-server > ./log/map-server.log 2>&1 &
    echo "$(date) - Map server reiniciado"
  fi
  
  exit 1
fi

# Verificar conexão com o banco de dados
mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "$(date) - Falha na conexão com o banco de dados!"
  exit 1
fi

# Repara tabelas corrompidas se necessário
TABLES_TO_CHECK=$(mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "SHOW TABLES" | grep -v "Tables_in")
  
for TABLE in $TABLES_TO_CHECK; do
  mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "CHECK TABLE $TABLE" | grep -i "crashed" > /dev/null
  if [ $? -eq 0 ]; then
    echo "$(date) - Reparando tabela $TABLE..."
    mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "REPAIR TABLE $TABLE"
  fi
done

echo "$(date) - Verificação concluída. Todos os serviços estão funcionando corretamente."
exit 0
EOF

  chmod +x /home/rathena/scripts/check_servers.sh
fi

# Configura o cron para monitoramento automático se habilitado
if [ "${AUTO_RESTART_SERVICES:-"true"}" = "true" ] && command -v crontab > /dev/null; then
  echo "Configurando monitoramento automático..."
  (crontab -l 2>/dev/null || echo "") | grep -v "check_servers.sh" > /tmp/crontab
  echo "*/5 * * * * /home/rathena/scripts/check_servers.sh >> /home/rathena/rAthena/log/monitor.log 2>&1" >> /tmp/crontab
  crontab /tmp/crontab
  rm /tmp/crontab
  
  # Iniciar o serviço cron se estiver disponível
  if command -v service > /dev/null && command -v cron > /dev/null; then
    service cron start || true
  fi
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

# Criar um arquivo com os PIDs para facilitar o gerenciamento
echo "$LOGINPID" > ./log/login.pid
echo "$CHARPID" > ./log/char.pid
echo "$MAPPID" > ./log/map.pid
[ -n "$WEBPID" ] && echo "$WEBPID" > ./log/web.pid

echo "Todos os servidores foram iniciados. Logs disponíveis em ./log/"
echo "Pressione Ctrl+C para encerrar."
echo "PIDs: Login=$LOGINPID, Char=$CHARPID, Map=$MAPPID"

# Tratamento de sinal para desligamento limpo
trap 'echo "Recebido sinal para encerrar, fechando servidores..."; kill -TERM $LOGINPID $CHARPID $MAPPID $WEBPID 2>/dev/null; exit 0' TERM INT QUIT

# Monitorar os servidores e executar verificações de saúde periódicas
echo "Iniciando monitoramento contínuo..."
LOG_FILE="./log/monitor.log"
echo "$(date) - Monitoramento iniciado" > $LOG_FILE

# Loop principal de monitoramento
while true; do
  # Verificar se os processos ainda estão rodando
  for PID in $LOGINPID $CHARPID $MAPPID $WEBPID; do
    if [ -n "$PID" ] && ! kill -0 $PID 2>/dev/null; then
      echo "$(date) - ALERTA: Processo $PID não está mais rodando!" | tee -a $LOG_FILE
      
      # Identificar qual servidor falhou
      if [ "$PID" = "$LOGINPID" ]; then
        echo "$(date) - Reiniciando login-server..." | tee -a $LOG_FILE
        ./login-server > ./log/login-server.log 2>&1 &
        LOGINPID=$!
        echo "$LOGINPID" > ./log/login.pid
      elif [ "$PID" = "$CHARPID" ]; then
        echo "$(date) - Reiniciando char-server..." | tee -a $LOG_FILE
        ./char-server > ./log/char-server.log 2>&1 &
        CHARPID=$!
        echo "$CHARPID" > ./log/char.pid
      elif [ "$PID" = "$MAPPID" ]; then
        echo "$(date) - Reiniciando map-server..." | tee -a $LOG_FILE
        ./map-server > ./log/map-server.log 2>&1 &
        MAPPID=$!
        echo "$MAPPID" > ./log/map.pid
      elif [ -n "$WEBPID" ] && [ "$PID" = "$WEBPID" ]; then
        echo "$(date) - Reiniciando web-server..." | tee -a $LOG_FILE
        ./web-server > ./log/web-server.log 2>&1 &
        WEBPID=$!
        echo "$WEBPID" > ./log/web.pid
      fi
    fi
  done
  
  # Executar verificação periódica a cada 30 segundos
  sleep 30
done