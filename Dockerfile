# Usar Debian 10 como base
FROM debian:10

# Adicione estas linhas ao seu Dockerfile existente
RUN apt-get update && apt-get install -y \
  git \
  make \
  libmariadb-dev \
  libmariadbclient-dev \
  libmariadbclient-dev-compat \
  gcc \
  g++ \
  zlib1g-dev \
  libpcre3-dev \
  dos2unix \
  nano \
  mariadb-client \
  screen \
  procps \
  cron \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Criar um usuário não-root para rodar o servidor
RUN useradd -m -s /bin/bash rathena

# Copiar o diretório de script e dar permissão
COPY --chown=rathena:rathena start.sh /home/rathena/
RUN chmod +x /home/rathena/start.sh

# Mudar para o usuário rathena
USER rathena

# start.sh
RUN echo '#!/bin/bash\n\ncd /home/rathena/rAthena\n\n# Variáveis do banco de dados\nMYSQL_HOST=${MYSQL_HOST:-"db"}\nMYSQL_PORT=${MYSQL_PORT:-"3306"}\nMYSQL_USER=${MYSQL_USER:-"ragnarok"}\nMYSQL_PASS=${MYSQL_PASS:-"ragnarok"}\nMYSQL_DB=${MYSQL_DB:-"ragnarok"}\n\n# Verificar se precisamos configurar o banco de dados\nif [ ! -f ".db_configured" ]; then\n  echo "Aguardando o serviço do MySQL iniciar..."\n  \n  # Copiar os arquivos de configuração\n  echo "Verificando arquivos de configuração..."\n  for conf_example in $(find ./conf -name "*.conf.example" 2>/dev/null); do\n    conf_file="${conf_example%.example}"\n    if [ ! -f "$conf_file" ]; then\n      echo "Copiando $conf_example para $conf_file"\n      cp "$conf_example" "$conf_file"\n    fi\n  done\n  \n  # Verificar se a pasta import existe\n  if [ ! -d "./conf/import" ]; then\n    mkdir -p ./conf/import\n    if [ -d "./conf/import-tmpl" ]; then\n      cp ./conf/import-tmpl/* ./conf/import/ 2>/dev/null || true\n    fi\n  fi\n  \n  # Aguardar o MySQL ficar disponível com retry\n  MAX_RETRY=30\n  RETRY=0\n  until mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1" >/dev/null 2>&1; do\n    RETRY=$((RETRY+1))\n    if [ $RETRY -ge $MAX_RETRY ]; then\n      echo "Falha ao conectar ao MySQL após $MAX_RETRY tentativas. Verifique se o servidor MySQL está em execução."\n      exit 1\n    fi\n    echo "Aguardando MySQL em $MYSQL_HOST:$MYSQL_PORT... (tentativa $RETRY/$MAX_RETRY)"\n    sleep 5\n  done\n  echo "Conexão com MySQL estabelecida com sucesso!"\n  \n  # Verificar se o banco de dados existe, criar se não existir\n  DB_EXISTS=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES LIKE '"'"'$MYSQL_DB'"'"';" 2>/dev/null | grep -c "$MYSQL_DB")\n  if [ "$DB_EXISTS" -eq 0 ]; then\n    echo "Criando banco de dados $MYSQL_DB..."\n    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE $MYSQL_DB;" 2>/dev/null\n  fi\n' > /home/rathena/start.sh && \
  echo '  # Configurar conexão com banco de dados\n  if [ -f "conf/inter_athena.conf" ]; then\n    echo "Configurando conexão com o banco de dados..."\n    sed -i "s/127.0.0.1/$MYSQL_HOST/g" conf/inter_athena.conf\n    \n    # Configurar login_server_ip\n    if grep -q "login_server_ip:" conf/inter_athena.conf; then\n      sed -i "s/^login_server_ip: .*$/login_server_ip: $MYSQL_HOST/" conf/inter_athena.conf\n      sed -i "s/^login_server_port: .*$/login_server_port: $MYSQL_PORT/" conf/inter_athena.conf\n      sed -i "s/^login_server_id: .*$/login_server_id: $MYSQL_USER/" conf/inter_athena.conf\n      sed -i "s/^login_server_pw: .*$/login_server_pw: $MYSQL_PASS/" conf/inter_athena.conf\n      sed -i "s/^login_server_db: .*$/login_server_db: $MYSQL_DB/" conf/inter_athena.conf\n    fi\n    \n    # Configurar char_server_ip\n    if grep -q "char_server_ip:" conf/inter_athena.conf; then\n      sed -i "s/^char_server_ip: .*$/char_server_ip: $MYSQL_HOST/" conf/inter_athena.conf\n      sed -i "s/^char_server_port: .*$/char_server_port: $MYSQL_PORT/" conf/inter_athena.conf\n      sed -i "s/^char_server_id: .*$/char_server_id: $MYSQL_USER/" conf/inter_athena.conf\n      sed -i "s/^char_server_pw: .*$/char_server_pw: $MYSQL_PASS/" conf/inter_athena.conf\n      sed -i "s/^char_server_db: .*$/char_server_db: $MYSQL_DB/" conf/inter_athena.conf\n    fi\n    \n    # Configurar map_server_ip\n    if grep -q "map_server_ip:" conf/inter_athena.conf; then\n      sed -i "s/^map_server_ip: .*$/map_server_ip: $MYSQL_HOST/" conf/inter_athena.conf\n      sed -i "s/^map_server_port: .*$/map_server_port: $MYSQL_PORT/" conf/inter_athena.conf\n      sed -i "s/^map_server_id: .*$/map_server_id: $MYSQL_USER/" conf/inter_athena.conf\n      sed -i "s/^map_server_pw: .*$/map_server_pw: $MYSQL_PASS/" conf/inter_athena.conf\n      sed -i "s/^map_server_db: .*$/map_server_db: $MYSQL_DB/" conf/inter_athena.conf\n    fi\n' >> /home/rathena/start.sh && \
  echo '    # Configurar log_db_ip\n    if grep -q "log_db_ip:" conf/inter_athena.conf; then\n      sed -i "s/^log_db_ip: .*$/log_db_ip: $MYSQL_HOST/" conf/inter_athena.conf\n      sed -i "s/^log_db_port: .*$/log_db_port: $MYSQL_PORT/" conf/inter_athena.conf\n      sed -i "s/^log_db_id: .*$/log_db_id: $MYSQL_USER/" conf/inter_athena.conf\n      sed -i "s/^log_db_pw: .*$/log_db_pw: $MYSQL_PASS/" conf/inter_athena.conf\n      sed -i "s/^log_db_db: .*$/log_db_db: $MYSQL_DB/" conf/inter_athena.conf\n    fi\n    \n    # Configurar web_server_ip\n    if grep -q "web_server_ip:" conf/inter_athena.conf; then\n      sed -i "s/^web_server_ip: .*$/web_server_ip: $MYSQL_HOST/" conf/inter_athena.conf\n      sed -i "s/^web_server_port: .*$/web_server_port: $MYSQL_PORT/" conf/inter_athena.conf\n      sed -i "s/^web_server_id: .*$/web_server_id: $MYSQL_USER/" conf/inter_athena.conf\n      sed -i "s/^web_server_pw: .*$/web_server_pw: $MYSQL_PASS/" conf/inter_athena.conf\n      sed -i "s/^web_server_db: .*$/web_server_db: $MYSQL_DB/" conf/inter_athena.conf\n    fi\n  fi\n  \n  # Configurar login_athena.conf\n  if [ -f "conf/login_athena.conf" ]; then\n    echo "Configurando login_athena.conf..."\n    # Certificar-se de que o login server está ouvindo em todas as interfaces\n    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/login_athena.conf\n    \n    # Adicionar opções de segurança\n    if ! grep -q "ipban_enable:" conf/login_athena.conf; then\n      echo "ipban_enable: yes" >> conf/login_athena.conf\n    else\n      sed -i "s/^ipban_enable: .*$/ipban_enable: yes/" conf/login_athena.conf\n    fi\n  fi\n' >> /home/rathena/start.sh && \
  echo '  # Configurar char_athena.conf\n  if [ -f "conf/char_athena.conf" ]; then\n    echo "Configurando char_athena.conf..."\n    # Configurar o IP do login server para o próprio contêiner\n    sed -i "s/^login_ip: .*$/login_ip: 127.0.0.1/" conf/char_athena.conf\n    # Certificar-se de que o char server está ouvindo em todas as interfaces\n    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/char_athena.conf\n  fi\n  \n  # Configurar map_athena.conf\n  if [ -f "conf/map_athena.conf" ]; then\n    echo "Configurando map_athena.conf..."\n    # Configurar o IP do char server para o próprio contêiner\n    sed -i "s/^char_ip: .*$/char_ip: 127.0.0.1/" conf/map_athena.conf\n    # Certificar-se de que o map server está ouvindo em todas as interfaces\n    sed -i "s/^bind_ip: .*$/bind_ip: 0.0.0.0/" conf/map_athena.conf\n    \n    # Adicionar otimizações de cache de mapas\n    if ! grep -q "map_cache_enabled:" conf/map_athena.conf; then\n      echo "map_cache_enabled: yes" >> conf/map_athena.conf\n      echo "map_cache_file: db/map_cache.dat" >> conf/map_athena.conf\n    else\n      sed -i "s/^map_cache_enabled: .*$/map_cache_enabled: yes/" conf/map_athena.conf\n    fi\n    \n    # Otimizações de desempenho\n    if ! grep -q "mob_cache_interval:" conf/map_athena.conf; then\n      echo "mob_cache_interval: 60" >> conf/map_athena.conf\n    fi\n  fi\n' >> /home/rathena/start.sh && \
  echo '# Criar as tabelas no banco de dados somente se não existirem\necho "Verificando se o banco de dados já está configurado..."\nTABLES_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"'"'$MYSQL_DB'"'"';" 2>/dev/null | tail -n 1)\n\nif [ "$TABLES_COUNT" -lt 10 ]; then\n  echo "Criando tabelas no banco de dados..."\n  for sql_file in sql-files/*.sql; do\n    echo "Importando $sql_file..."\n    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" < "$sql_file" || true\n  done\nelse\n  echo "Banco de dados já possui tabelas, pulando importação."\nfi\n  touch .db_configured\nfi\n\n# Configurar o cron para monitoramento automático se habilitado\nif [ "${AUTO_RESTART_SERVICES:-"true"}" = "true" ] && command -v crontab > /dev/null; then\n  echo "Configurando monitoramento automático..."\n  (crontab -l 2>/dev/null || echo "") | grep -v "check_servers.sh" > /tmp/crontab\n  echo "*/10 * * * * /home/rathena/scripts/check_servers.sh >> /home/rathena/rAthena/log/monitor.log 2>&1" >> /tmp/crontab\n  crontab /tmp/crontab\n  rm /tmp/crontab\nfi\n' >> /home/rathena/start.sh && \
  echo '# Adicionando verificação de integridade do banco de dados - apenas se AUTO_REPAIR_DB=true\nif [ "${AUTO_REPAIR_DB:-"false"}" = "true" ]; then\n  echo "Verificando integridade do banco de dados..."\n  # Verificar apenas uma vez durante a inicialização, não continuamente\n  mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "\n    USE $MYSQL_DB;\n    CHECK TABLE login, char, global_reg_value;" 2>/dev/null\nfi\n\n# Verifica se o diretório de log existe\nif [ ! -d "./log" ]; then\n  mkdir -p ./log\nfi\n\n# Criar o script de verificação de servidores se não existir\nif [ ! -f "/home/rathena/scripts/check_servers.sh" ]; then\n  mkdir -p /home/rathena/scripts\n  cat > /home/rathena/scripts/check_servers.sh << '"'"'EOF'"'"'\n#!/bin/bash\n\n# Variáveis do banco de dados\nMYSQL_HOST=${MYSQL_HOST:-"db"}\nMYSQL_PORT=${MYSQL_PORT:-"3306"}\nMYSQL_USER=${MYSQL_USER:-"ragnarok"}\nMYSQL_PASS=${MYSQL_PASS:-"ragnarok"}\nMYSQL_DB=${MYSQL_DB:-"ragnarok"}\n\n# Verificar se os servidores estão rodando\nLOGIN_RUNNING=$(ps aux | grep login-server | grep -v grep | wc -l)\nCHAR_RUNNING=$(ps aux | grep char-server | grep -v grep | wc -l)\nMAP_RUNNING=$(ps aux | grep map-server | grep -v grep | wc -l)\n\nif [ $LOGIN_RUNNING -eq 0 ] || [ $CHAR_RUNNING -eq 0 ] || [ $MAP_RUNNING -eq 0 ]; then\n  echo "$(date) - Um ou mais servidores não estão rodando. Tentando reiniciar..."\n  \n  # Tenta reiniciar os serviços que não estão rodando\n  if [ $LOGIN_RUNNING -eq 0 ]; then\n    cd /home/rathena/rAthena\n    ./login-server > ./log/login-server.log 2>&1 &\n    echo "$(date) - Login server reiniciado"\n  fi\n  \n  if [ $CHAR_RUNNING -eq 0 ]; then\n    cd /home/rathena/rAthena\n    ./char-server > ./log/char-server.log 2>&1 &\n    echo "$(date) - Char server reiniciado"\n  fi\n  \n  if [ $MAP_RUNNING -eq 0 ]; then\n    cd /home/rathena/rAthena\n    ./map-server > ./log/map-server.log 2>&1 &\n    echo "$(date) - Map server reiniciado"\n  fi\n  \n  exit 1\nfi\n' >> /home/rathena/start.sh && \
  echo '# Verificar conexão com o banco de dados\nmysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SELECT 1" > /dev/null 2>&1\nif [ $? -ne 0 ]; then\n  echo "$(date) - Falha na conexão com o banco de dados!"\n  exit 1\nfi\n\n# Verificar problemas de desempenho do servidor\nCPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '"'"'{print 100 - $1}'"'"')\nMEM_USAGE=$(free | grep Mem | awk '"'"'{print $3/$2 * 100.0}'"'"')\n\nif (( $(echo "$CPU_USAGE > 90" | bc -l) )); then\n  echo "$(date) - ALERTA: Uso de CPU elevado: $CPU_USAGE%"\nfi\n\nif (( $(echo "$MEM_USAGE > 90" | bc -l) )); then\n  echo "$(date) - ALERTA: Uso de memória elevado: $MEM_USAGE%"\nfi\n\n# Repara tabelas corrompidas apenas se necessário e com frequência reduzida\n# Executa a cada 5 minutos mas só checa tabelas uma vez por hora\nMINUTE=$(date +%M)\nif [ $((MINUTE % 60)) -eq 0 ]; then\n  # Verificar se há tabelas corrompidas\n  TABLES_TO_CHECK=$(mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "SHOW TABLES" | grep -v "Tables_in")\n    \n  for TABLE in $TABLES_TO_CHECK; do\n    mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "CHECK TABLE $TABLE" | grep -i "crashed" > /dev/null\n    if [ $? -eq 0 ]; then\n      echo "$(date) - Reparando tabela $TABLE..."\n      mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -e "REPAIR TABLE $TABLE"\n    fi\n  done\nfi\n\necho "$(date) - Verificação concluída. Todos os serviços estão funcionando corretamente."\nexit 0\nEOF\n  chmod +x /home/rathena/scripts/check_servers.sh\nfi\n\n# Iniciar os servidores\ncd /home/rathena/rAthena\n\necho "Iniciando os servidores..."\n./login-server > ./log/login-server.log 2>&1 &\nsleep 3\n./char-server > ./log/char-server.log 2>&1 &\nsleep 3\n./map-server > ./log/map-server.log 2>&1 &\n# ./web-server > ./log/web-server.log 2>&1 &\n\n# Manter o container rodando\necho "Todos os servidores iniciados. Monitorando logs..."\nexec tail -f ./log/*.log\n' >> /home/rathena/start.sh && \
  chmod +x /home/rathena/start.sh

WORKDIR /home/rathena

# Criar um diretório temporário para o código do rAthena
RUN mkdir -p /home/rathena/temp

# Copiar o diretório local rathena para o diretório temporário (será ignorado se não existir)
COPY --chown=rathena:rathena rathena/ /home/rathena/temp/

# Script para configurar o rAthena (clonar ou usar o existente)
RUN mkdir -p /home/rathena/rAthena && \
  if [ -f "/home/rathena/temp/configure" ]; then \
  cp -R /home/rathena/temp/* /home/rathena/rAthena/; \
  else \
  git clone https://github.com/rathena/rathena.git /home/rathena/rAthena; \
  fi && \
  rm -rf /home/rathena/temp

# Configurar e compilar
WORKDIR /home/rathena/rAthena
RUN ./configure && make clean && make server

# Tornar os binários executáveis
RUN chmod a+x login-server && \
  chmod a+x char-server && \
  chmod a+x map-server && \
  # chmod a+x web-server && \
  dos2unix athena-start

# Preparar diretórios de configuração
RUN mkdir -p /home/rathena/rAthena/conf/import && \
  if [ -d "/home/rathena/rAthena/conf/import-tmpl" ]; then \
  cp /home/rathena/rAthena/conf/import-tmpl/* /home/rathena/rAthena/conf/import/ 2>/dev/null || true; \
  fi && \
  for conf_example in $(find /home/rathena/rAthena/conf -name "*.conf.example"); do \
  conf_file="${conf_example%.example}"; \
  echo "Copiando $conf_example para $conf_file"; \
  cp "$conf_example" "$conf_file"; \
  done

# Expor as portas necessárias (ajuste conforme necessário)
# Login Server
EXPOSE 6900
# Char Server
EXPOSE 6121
# Map Server
EXPOSE 5121
# Web Server
# EXPOSE 8888

# Iniciar script
CMD ["/home/rathena/start.sh"]