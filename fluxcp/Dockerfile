FROM php:7.4-apache

# Instalar extensões PHP necessárias
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    libtidy-dev \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo pdo_mysql zip tidy xml

# Configurar o Apache para usar mod_rewrite
RUN a2enmod rewrite

# Adicionar configuração ServerName para evitar o aviso AH00558
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expor porta 80
EXPOSE 80

# Iniciar Apache em primeiro plano
CMD ["apache2-foreground"]