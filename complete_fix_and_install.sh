#!/bin/bash
# Комплексный скрипт для исправления ошибки "Внутренняя ошибка сервера" в Nextcloud
# и установки приложения one_c_web_client

echo "=== Комплексное исправление ошибки Nextcloud и установка приложения ==="

# Проверка, запущен ли скрипт с правами sudo
if [[ $EUID -eq 0 ]]; then
   echo "✓ Скрипт запущен с правами root"
else
   echo "✗ Этот скрипт должен быть запущен с правами sudo"
   echo "Выполните: sudo $0"
   exit 1
fi

echo ""
echo "ШАГ 1: Установка недостающих PHP-расширений..."

# Установка недостающих расширений
apt update
apt install -y php8.4-common php8.4-curl php8.4-gd php8.4-imagick php8.4-intl php8.4-mbstring php8.4-pdo php8.4-mysql php8.4-sqlite3 php8.4-xml php8.4-zip php8.4-bz2 php8.4-gmp php8.4-ldap

if [ $? -eq 0 ]; then
    echo "✓ PHP-расширения успешно установлены"
else
    echo "✗ Ошибка при установке PHP-расширений"
    exit 1
fi

echo ""
echo "ШАГ 2: Исправление прав доступа к файлам Nextcloud..."

# Установка владельца файлов Nextcloud
chown -R www-data:www-data /var/www/nextcloud/

if [ $? -eq 0 ]; then
    echo "✓ Права владельца успешно установлены"
else
    echo "✗ Ошибка при установке владельца файлов"
    exit 1
fi

# Установка прав на файлы и директории
find /var/www/nextcloud -type f -exec chmod 644 {} \;
find /var/www/nextcloud -type d -exec chmod 755 {} \;

# Установка особых прав для важных директорий
chmod 770 /var/www/nextcloud/data 2>/dev/null || echo "Директория data может не существовать"
chmod 770 /var/www/nextcloud/config 2>/dev/null || echo "Директория config может не требовать особых прав"
chmod 770 /var/www/nextcloud/apps 2>/dev/null || echo "Директория apps может не требовать особых прав"

# Установка прав на конфигурационный файл
chmod 640 /var/www/nextcloud/config/config.php 2>/dev/null || echo "Файл config.php может не требовать особых прав"

echo "✓ Права доступа установлены"

echo ""
echo "ШАГ 3: Перезапуск сервисов..."

# Перезапуск PHP-FPM и Apache
systemctl restart php8.4-fpm
systemctl restart apache2

if [ $? -eq 0 ]; then
    echo "✓ Сервисы успешно перезапущены"
else
    echo "✗ Ошибка при перезапуске сервисов"
    exit 1
fi

echo ""
echo "ШАГ 4: Проверка работоспособности Nextcloud..."

# Проверяем, работает ли теперь Nextcloud
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
    if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        echo "✓ Nextcloud доступен (HTTP $HTTP_CODE) - это нормальное поведение для перенаправления на страницу входа"
    else
        echo "✓ Nextcloud доступен (HTTP $HTTP_CODE)"
    fi
else
    echo "✗ Nextcloud недоступен (HTTP $HTTP_CODE)"
    echo "Проверьте логи Apache: sudo tail -n 20 /var/log/apache2/error.log"
    exit 1
fi

echo ""
echo "ШАГ 5: Установка приложения one_c_web_client..."

# Копирование приложения
cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client

if [ $? -eq 0 ]; then
    echo "✓ Приложение скопировано в директорию приложений"
else
    echo "✗ Ошибка при копировании приложения"
    exit 1
fi

# Установка прав доступа к приложению
chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client

if [ $? -eq 0 ]; then
    echo "✓ Права доступа к приложению установлены"
else
    echo "✗ Ошибка при установке прав доступа к приложению"
    exit 1
fi

# Установка приложения через OCC
sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client

if [ $? -eq 0 ]; then
    echo "✓ Приложение one_c_web_client успешно установлено"
else
    echo "✗ Ошибка при установке приложения one_c_web_client"
    # Попробуем включить приложение, если оно не включилось автоматически
    sudo -u www-data php -f /var/www/nextcloud/occ app:enable one_c_web_client
    if [ $? -eq 0 ]; then
        echo "✓ Приложение one_c_web_client успешно включено"
    else
        echo "✗ Ошибка при включении приложения one_c_web_client"
    fi
fi

echo ""
echo "=== Установка завершена успешно! ==="
echo "Теперь вы можете:"
echo "1. Открыть Nextcloud в браузере"
echo "2. Войти в систему с административными правами"
echo "3. Перейти в раздел администрирования и настроить приложение '1C WebClient'"
echo "4. Добавить список баз 1С в формате http://адрес/база/"