FROM php:8.3-apache

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libpq-dev \
    libsodium-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    ghostscript \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Настройка и установка PHP расширений
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    intl \
    mysqli \
    pgsql \
    pdo_pgsql \
    pdo_mysql \
    zip \
    soap \
    exif \
    opcache \
    sodium \
    mbstring \
    xml \
    curl \
    fileinfo

# Включение Apache mod_rewrite
RUN a2enmod rewrite

# Настройка PHP для Moodle
RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/moodle.ini

# Настройка OPcache для продакшена
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/opcache.ini

# Установка рабочей директории
WORKDIR /var/www/html

# Копирование файлов проекта
COPY . /var/www/html/

# Создание директории для moodledata
RUN mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/moodledata \
    && chmod -R 0777 /var/www/moodledata

# Настройка прав доступа
RUN chown -R www-data:www-data /var/www/html

# Копирование конфигурации Apache
RUN echo '<Directory /var/www/html/public>\n\
    Options -Indexes +FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/moodle.conf \
    && a2enconf moodle

# Настройка DocumentRoot на public директорию
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Копирование и настройка скрипта запуска
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Открытие порта
EXPOSE 80

# Использование скрипта запуска
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

