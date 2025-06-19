# -------- Stage 1: Laravel Build ----------
FROM php:8.2-fpm AS builder

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory
WORKDIR /var/www/html

# Copy Laravel project
COPY . .

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install Laravel dependencies
RUN composer install --no-dev --no-interaction --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# -------- Stage 2: Production Image ----------
FROM php:8.2-fpm

# ✅ Install runtime + PHP build dependencies (including zip support)
RUN apt-get update && apt-get install -y \
    nginx supervisor procps unzip zip libzip-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add missing PHP-FPM config (if not present)
RUN mkdir -p /usr/local/etc/php-fpm.d && echo "\
[www]\n\
user = www-data\n\
group = www-data\n\
listen = 127.0.0.1:9000\n\
listen.owner = www-data\n\
listen.group = www-data\n\
pm = dynamic\n\
pm.max_children = 5\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3\n\
chdir = /\n\
" > /usr/local/etc/php-fpm.d/www.conf

# Copy Laravel application from builder
COPY --from=builder /var/www/html /var/www/html

# Copy Nginx configuration
COPY default.conf /etc/nginx/sites-available/default

RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy Supervisor configuration
COPY laravel-k8s/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory
WORKDIR /var/www/html

# Expose port
EXPOSE 80

# Start Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
