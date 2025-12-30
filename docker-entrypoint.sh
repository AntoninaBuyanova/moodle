#!/bin/bash
set -e

# Ожидание готовности базы данных
if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database to be ready..."
    sleep 5
fi

# Создание директории moodledata если её нет
if [ ! -d "/var/www/moodledata" ]; then
    mkdir -p /var/www/moodledata
    chown -R www-data:www-data /var/www/moodledata
    chmod -R 0777 /var/www/moodledata
fi

# Создание config.php из переменных окружения
if [ -n "$DATABASE_URL" ]; then
    echo "Generating config.php from environment variables..."
    echo "DATABASE_URL: $DATABASE_URL"
    
    # Убираем postgresql:// или postgres:// из начала
    DB_URL_CLEAN=$(echo "$DATABASE_URL" | sed -E 's|^postgres(ql)?://||')
    
    # Извлекаем user:password@host:port/dbname
    DB_USER=$(echo "$DB_URL_CLEAN" | sed -E 's|^([^:]+):.*|\1|')
    DB_PASS=$(echo "$DB_URL_CLEAN" | sed -E 's|^[^:]+:([^@]+)@.*|\1|')
    DB_HOST_PORT_DB=$(echo "$DB_URL_CLEAN" | sed -E 's|^[^@]+@||')
    
    # Проверяем есть ли порт
    if echo "$DB_HOST_PORT_DB" | grep -q ':'; then
        DB_HOST=$(echo "$DB_HOST_PORT_DB" | sed -E 's|^([^:]+):.*|\1|')
        DB_PORT=$(echo "$DB_HOST_PORT_DB" | sed -E 's|^[^:]+:([0-9]+)/.*|\1|')
        DB_NAME=$(echo "$DB_HOST_PORT_DB" | sed -E 's|^[^/]+/([^?]+).*|\1|')
    else
        DB_HOST=$(echo "$DB_HOST_PORT_DB" | sed -E 's|^([^/]+)/.*|\1|')
        DB_PORT="5432"
        DB_NAME=$(echo "$DB_HOST_PORT_DB" | sed -E 's|^[^/]+/([^?]+).*|\1|')
    fi
    
    DB_TYPE="pgsql"
    
    echo "Parsed: host=$DB_HOST port=$DB_PORT user=$DB_USER db=$DB_NAME"

    # Определение WWW ROOT (убираем trailing slash если есть)
    WWW_ROOT="${MOODLE_WWW_ROOT:-https://${RENDER_EXTERNAL_HOSTNAME}}"
    WWW_ROOT="${WWW_ROOT%/}"
    
    # Создание config.php
    cat > /var/www/html/public/config.php << EOF
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

// Database settings
\$CFG->dbtype    = '${DB_TYPE}';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${DB_HOST}';
\$CFG->dbname    = '${DB_NAME}';
\$CFG->dbuser    = '${DB_USER}';
\$CFG->dbpass    = '${DB_PASS}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = [
    'dbpersist' => false,
    'dbport'    => '${DB_PORT}',
];

// Site URL
\$CFG->wwwroot   = '${WWW_ROOT}';

// Data directory
\$CFG->dataroot  = '/var/www/moodledata';

// Router configuration
\$CFG->routerconfigured = false;

// Directory permissions
\$CFG->directorypermissions = 02777;

// Admin directory
\$CFG->admin = 'admin';

// Force SSL proxy (Render uses HTTPS)
\$CFG->sslproxy = true;

// Disable IP check for sessions (fixes "original IP address" error on Render)
\$CFG->tracksessionip = false;

// Session handling - use file sessions
\$CFG->session_handler_class = '\core\session\file';
\$CFG->session_file_save_path = '/var/www/moodledata/sessions';

// Additional recommended settings for production
\$CFG->cachejs = true;
\$CFG->cachetemplates = true;
\$CFG->langstringcache = true;

require_once(__DIR__ . '/lib/setup.php');
EOF

    echo "config.php generated successfully"
fi

# Проверка и создание необходимых поддиректорий
mkdir -p /var/www/moodledata/temp
mkdir -p /var/www/moodledata/cache
mkdir -p /var/www/moodledata/sessions
mkdir -p /var/www/moodledata/filedir
mkdir -p /var/www/moodledata/trashdir
chown -R www-data:www-data /var/www/moodledata

echo "Moodle container starting..."

# Выполнение оригинальной команды
exec "$@"
