#!/bin/bash

# Configurar permissões
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Verificar se o diretório /var/www/html/data é gravável
if [ ! -d "/var/www/html/data" ]; then
    mkdir -p /var/www/html/data
    chown -R www-data:www-data /var/www/html/data
    chmod -R 777 /var/www/html/data
fi

# Verificar se o diretório de cache está configurado
if [ ! -d "/var/www/html/data/tmp/DoctrineCache" ]; then
    mkdir -p /var/www/html/data/tmp/DoctrineCache
    chown -R www-data:www-data /var/www/html/data/tmp
    chmod -R 777 /var/www/html/data/tmp
fi

# Iniciar Apache
apache2-foreground