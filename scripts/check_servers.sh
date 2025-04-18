#!/bin/bash

# Verificar se os servidores estão rodando
LOGIN_RUNNING=$(ps aux | grep login-server | grep -v grep | wc -l)
CHAR_RUNNING=$(ps aux | grep char-server | grep -v grep | wc -l)
MAP_RUNNING=$(ps aux | grep map-server | grep -v grep | wc -l)

if [ $LOGIN_RUNNING -eq 0 ] || [ $CHAR_RUNNING -eq 0 ] || [ $MAP_RUNNING -eq 0 ]; then
  echo "Um ou mais servidores não estão rodando. Tentando reiniciar..."
  
  # Tenta reiniciar os serviços que não estão rodando
  if [ $LOGIN_RUNNING -eq 0 ]; then
    cd /home/rathena/rAthena
    ./login-server > ./log/login-server.log 2>&1 &
    echo "Login server reiniciado"
  fi
  
  if [ $CHAR_RUNNING -eq 0 ]; then
    cd /home/rathena/rAthena
    ./char-server > ./log/char-server.log 2>&1 &
    echo "Char server reiniciado"
  fi
  
  if [ $MAP_RUNNING -eq 0 ]; then
    cd /home/rathena/rAthena
    ./map-server > ./log/map-server.log 2>&1 &
    echo "Map server reiniciado"
  fi
  
  exit 1
fi

# Verificar conexão com o banco de dados
mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Falha na conexão com o banco de dados!"
  exit 1
fi

# Repara tabelas corrompidas se necessário
if [ "$AUTO_REPAIR_DB" = "true" ]; then
  TABLES_TO_CHECK=$(mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "SHOW TABLES" | grep -v "Tables_in")
  
  for TABLE in $TABLES_TO_CHECK; do
    mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "CHECK TABLE $TABLE" | grep -i "crashed" > /dev/null
    if [ $? -eq 0 ]; then
      echo "Reparando tabela $TABLE..."
      mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "REPAIR TABLE $TABLE"
    fi
  done
fi

echo "Todos os serviços estão funcionando corretamente."
exit 0