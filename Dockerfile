# Stage 1: Build PHP dependencies
FROM php:8.2-fpm as php

# Install dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory
WORKDIR /var/www/html

# Copy Laravel project into container
COPY . /var/www/html

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Install Laravel dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# -------------------------------------------
# Stage 2: Add Nginx with PHP-FPM
FROM nginx:alpine

# Install PHP-FPM runtime
RUN apk add --no-cache php8 php8-fpm supervisor

# Copy Laravel app from previous stage
COPY --from=php /var/www/html /var/www/html

# ✅ Corrected path to Nginx config file
COPY default.conf /etc/nginx/conf.d/default.conf

# Set working directory
WORKDIR /var/www/html

# Expose port for Nginx
EXPOSE 80

# Start both PHP-FPM and Nginx
CMD ["sh", "-c", "php-fpm8 -D && nginx -g 'daemon off;'"]
