FROM php:8.2-fpm

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory INSIDE laravel-starter folder
WORKDIR /var/www/html/laravel-starter

# Copy everything into /var/www/html/laravel-starter
COPY . /var/www/html/laravel-starter

# Mark project directory as safe for Git
RUN git config --global --add safe.directory /var/www/html/laravel-starter

# Install Composer and Laravel dependencies
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer install

# Set permissions
RUN chown -R www-data:www-data /var/www/html/laravel-starter && \
    chmod -R 755 /var/www/html/laravel-starter
