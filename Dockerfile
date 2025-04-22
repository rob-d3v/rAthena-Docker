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