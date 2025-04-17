# Usar Debian 10 como base
FROM debian:10

# Instalar dependências necessárias
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Criar um usuário não-root para rodar o servidor
RUN useradd -m -s /bin/bash rathena

# Mudar para o usuário rathena
USER rathena
WORKDIR /home/rathena

# Clonar o repositório rAthena
RUN git clone https://github.com/rathena/rathena.git /home/rathena/rAthena

# Configurar e compilar
WORKDIR /home/rathena/rAthena
RUN ./configure && make clean && make server

# Tornar os binários executáveis
RUN chmod a+x login-server && \
    chmod a+x char-server && \
    chmod a+x map-server && \
    chmod a+x web-server && \
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
EXPOSE 8888

# Script para iniciar os servidores
COPY --chown=rathena:rathena start.sh /home/rathena/
RUN chmod +x /home/rathena/start.sh

# Iniciar script
CMD ["/home/rathena/start.sh"]