#!/bin/bash
# Скрипт диагностики и восстановления Nextcloud

echo "=== Диагностика и восстановление Nextcloud ==="

# Проверяем, запущен ли веб-сервер
if systemctl is-active --quiet apache2; then
    echo "✓ Apache2 запущен"
else
    echo "✗ Apache2 не запущен"
    sudo systemctl start apache2
    if systemctl is-active --quiet apache2; then
        echo "✓ Apache2 успешно запущен"
    else
        echo "✗ Не удалось запустить Apache2"
        exit 1
    fi
fi

# Проверяем, запущен ли PHP-FPM
if pgrep php-fpm > /dev/null; then
    echo "✓ PHP-FPM запущен"
else
    echo "✗ PHP-FPM не запущен"
    sudo systemctl start php*-fpm
    if pgrep php-fpm > /dev/null; then
        echo "✓ PHP-FPM успешно запущен"
    else
        echo "✗ Не удалось запустить PHP-FPM"
        exit 1
    fi
fi

# Проверяем доступность Nextcloud через curl
echo "Проверяем доступность Nextcloud..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null)

if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Nextcloud доступен (HTTP $HTTP_CODE)"
else
    echo "✗ Nextcloud недоступен (HTTP $HTTP_CODE)"
fi

# Проверяем права доступа к файлам Nextcloud
echo "Проверяем права доступа к файлам Nextcloud..."
if [ -d "/var/www/nextcloud" ]; then
    OWNER=$(stat -c %U /var/www/nextcloud)
    if [ "$OWNER" = "www-data" ]; then
        echo "✓ Владелец файлов Nextcloud: $OWNER"
    else
        echo "⚠ Владелец файлов Nextcloud: $OWNER (ожидался www-data)"
        sudo chown -R www-data:www-data /var/www/nextcloud
        echo "✓ Права доступа исправлены"
    fi
else
    echo "✗ Директория /var/www/nextcloud не найдена"
    exit 1
fi

# Проверяем права на директорию data
if [ -d "/var/www/nextcloud/data" ]; then
    DATA_OWNER=$(stat -c %U /var/www/nextcloud/data)
    if [ "$DATA_OWNER" = "www-data" ]; then
        echo "✓ Владелец директории data: $DATA_OWNER"
    else
        echo "⚠ Владелец директории data: $DATA_OWNER (ожидался www-data)"
        sudo chown -R www-data:www-data /var/www/nextcloud/data
        echo "✓ Права доступа к директории data исправлены"
    fi
else
    echo "⚠ Директория /var/www/nextcloud/data не найдена"
fi

# Проверяем права на директорию config
if [ -d "/var/www/nextcloud/config" ]; then
    CONFIG_OWNER=$(stat -c %U /var/www/nextcloud/config)
    if [ "$CONFIG_OWNER" = "www-data" ]; then
        echo "✓ Владелец директории config: $CONFIG_OWNER"
    else
        echo "⚠ Владелец директории config: $CONFIG_OWNER (ожидался www-data)"
        sudo chown -R www-data:www-data /var/www/nextcloud/config
        echo "✓ Права доступа к директории config исправлены"
    fi
else
    echo "⚠ Директория /var/www/nextcloud/config не найдена"
fi

# Проверяем права на директорию apps
if [ -d "/var/www/nextcloud/apps" ]; then
    APPS_OWNER=$(stat -c %U /var/www/nextcloud/apps)
    if [ "$APPS_OWNER" = "www-data" ]; then
        echo "✓ Владелец директории apps: $APPS_OWNER"
    else
        echo "⚠ Владелец директории apps: $APPS_OWNER (ожидался www-data)"
        sudo chown -R www-data:www-data /var/www/nextcloud/apps
        echo "✓ Права доступа к директории apps исправлены"
    fi
else
    echo "⚠ Директория /var/www/nextcloud/apps не найдена"
fi

# Проверяем конфигурацию PHP
echo "Проверяем конфигурацию PHP..."
PHP_VERSION=$(php -r "echo PHP_VERSION;")
echo "Версия PHP: $PHP_VERSION"

# Проверяем расширения, необходимые для Nextcloud
REQUIRED_EXTENSIONS=("gd" "curl" "dom" "fileinfo" "iconv" "intl" "json" "mbstring" "openssl" "pdo" "zip" "xml" "zlib")
MISSING_EXTENSIONS=()

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if ! php -m | grep -q "^$ext$"; then
        MISSING_EXTENSIONS+=("$ext")
    fi
done

if [ ${#MISSING_EXTENSIONS[@]} -eq 0 ]; then
    echo "✓ Все необходимые расширения PHP установлены"
else
    echo "⚠ Отсутствуют следующие расширения PHP: ${MISSING_EXTENSIONS[*]}"
fi

# Перезапускаем веб-сервер для применения изменений
echo "Перезапускаем Apache2..."
sudo systemctl reload apache2

echo "=== Диагностика завершена ==="
echo "Если проблема сохраняется, проверьте логи Apache и PHP-FPM:"
echo "- sudo tail -f /var/log/apache2/error.log"
echo "- sudo journalctl -u php*-fpm -f"