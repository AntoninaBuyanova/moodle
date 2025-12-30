# Деплой Moodle на Render.com

Эта инструкция описывает как задеплоить Moodle на платформу Render.com.

## Требования

- Аккаунт на [Render.com](https://render.com)
- Репозиторий с кодом (GitHub, GitLab или Bitbucket)

## Способ 1: Автоматический деплой через Blueprint

### Шаг 1: Загрузите код в Git репозиторий

```bash
git init
git add .
git commit -m "Initial commit for Render deployment"
git remote add origin <your-repo-url>
git push -u origin main
```

### Шаг 2: Создайте Blueprint на Render

1. Войдите в [Render Dashboard](https://dashboard.render.com)
2. Нажмите **"New"** → **"Blueprint"**
3. Подключите ваш Git репозиторий
4. Render автоматически найдёт `render.yaml` и создаст:
   - Web Service для Moodle
   - PostgreSQL базу данных
   - Disk для хранения файлов

### Шаг 3: Настройте переменные окружения

После создания сервиса, добавьте переменную `MOODLE_WWW_ROOT`:

1. Откройте ваш Web Service в Render Dashboard
2. Перейдите в **"Environment"**
3. Добавьте переменную:
   - **Key:** `MOODLE_WWW_ROOT`
   - **Value:** `https://your-service-name.onrender.com`

### Шаг 4: Первая установка Moodle

1. Откройте ваш сайт: `https://your-service-name.onrender.com`
2. Следуйте мастеру установки Moodle:
   - Подтвердите требования системы
   - Создайте аккаунт администратора
   - Настройте сайт

## Способ 2: Ручной деплой

### Шаг 1: Создайте PostgreSQL базу данных

1. В Render Dashboard нажмите **"New"** → **"PostgreSQL"**
2. Настройте:
   - **Name:** `moodle-db`
   - **Database:** `moodle`
   - **User:** `moodle`
   - **Region:** Выберите ближайший регион
3. Нажмите **"Create Database"**
4. Скопируйте **Internal Database URL**

### Шаг 2: Создайте Web Service

1. В Render Dashboard нажмите **"New"** → **"Web Service"**
2. Подключите репозиторий
3. Настройте:
   - **Name:** `moodle`
   - **Region:** Тот же, что и база данных
   - **Runtime:** Docker
   - **Dockerfile Path:** `./Dockerfile`

### Шаг 3: Добавьте Disk

1. В настройках Web Service найдите **"Disks"**
2. Нажмите **"Add Disk"**:
   - **Name:** `moodledata`
   - **Mount Path:** `/var/www/moodledata`
   - **Size:** 10 GB (или больше)

### Шаг 4: Настройте переменные окружения

В **"Environment"** добавьте:

| Key | Value |
|-----|-------|
| `DATABASE_URL` | Internal Database URL из шага 1 |
| `MOODLE_WWW_ROOT` | `https://your-service-name.onrender.com` |

### Шаг 5: Деплой

Нажмите **"Deploy"** и дождитесь завершения сборки.

## Настройка Cron

Moodle требует регулярный запуск cron для фоновых задач.

### Вариант A: Render Cron Job

1. Создайте **"New"** → **"Cron Job"**
2. Настройте:
   - **Schedule:** `*/5 * * * *` (каждые 5 минут)
   - **Command:** `curl -s https://your-service-name.onrender.com/admin/cron.php`

### Вариант B: Внешний сервис

Используйте бесплатные сервисы:
- [cron-job.org](https://cron-job.org)
- [easycron.com](https://easycron.com)

Настройте запрос к:
```
https://your-service-name.onrender.com/admin/cron.php
```

## Рекомендуемые настройки Moodle

После установки рекомендуется:

### 1. Настроить кэширование

Перейдите в: **Администрирование** → **Плагины** → **Кэширование** → **Настройка**

### 2. Включить HTTPS

В `config.php` уже настроено:
```php
$CFG->sslproxy = true;
```

### 3. Настроить почту

Для отправки email настройте SMTP в:
**Администрирование** → **Сервер** → **Исходящая почта**

Рекомендуемые сервисы:
- [SendGrid](https://sendgrid.com) (бесплатно до 100 писем/день)
- [Mailgun](https://mailgun.com)
- [Amazon SES](https://aws.amazon.com/ses/)

## Масштабирование

### Увеличение ресурсов

1. Upgrade план Web Service (starter → standard → pro)
2. Увеличьте размер диска для moodledata
3. Upgrade план базы данных

### Оптимизация

1. Включите OPcache (уже настроен в Dockerfile)
2. Настройте Redis для сессий (требует дополнительного сервиса)
3. Используйте CDN для статических файлов

## Резервное копирование

### База данных

Render автоматически создаёт daily backups для платных планов PostgreSQL.

### Файлы Moodle

Регулярно делайте backup содержимого `/var/www/moodledata`:
1. Через admin CLI: `php admin/cli/backup.php`
2. Скачивайте backup файлы из Moodle admin

## Устранение проблем

### Ошибка подключения к базе данных

1. Проверьте `DATABASE_URL` в переменных окружения
2. Убедитесь, что Web Service и Database в одном регионе
3. Проверьте логи в Render Dashboard

### Ошибки прав доступа

Проверьте, что диск `/var/www/moodledata` примонтирован и имеет права записи.

### Медленная загрузка

1. Проверьте план (starter может быть медленным)
2. Оптимизируйте настройки кэширования в Moodle
3. Рассмотрите upgrade до standard/pro плана

### Просмотр логов

В Render Dashboard откройте ваш сервис и перейдите в **"Logs"**.

## Полезные ссылки

- [Render Documentation](https://render.com/docs)
- [Moodle Installation Guide](https://docs.moodle.org/en/Installing_Moodle)
- [Moodle Performance Guide](https://docs.moodle.org/en/Performance)

