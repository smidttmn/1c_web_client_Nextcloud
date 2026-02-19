#!/bin/bash
# Скрипт для установки необходимых PHP-расширений для Nextcloud

echo "Установка необходимых PHP-расширений для Nextcloud..."

# Определение используемой версии PHP
PHP_VERSION=$(php -r "echo substr(PHP_VERSION, 0, 3);")

echo "Обнаруженная версия PHP: $PHP_VERSION"

# Установка недостающих расширений
echo "Устанавливаем недостающие расширения..."

# Для Ubuntu/Debian систем
if [ -f /etc/debian_version ]; then
    echo "Обнаружена система на базе Debian/Ubuntu"
    
    # Установка PDO и других необходимых расширений
    sudo apt update
    sudo apt install -y php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-imagick php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring php${PHP_VERSION}-pdo php${PHP_VERSION}-mysql php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bz2 php${PHP_VERSION}-gmp php${PHP_VERSION}-ldap
    
    if [ $? -eq 0 ]; then
        echo "✓ Необходимые PHP-расширения успешно установлены"
    else
        echo "✗ Ошибка при установке PHP-расширений"
        exit 1
    fi
else
    echo "✗ Скрипт поддерживает только системы на базе Debian/Ubuntu"
    exit 1
fi

# Перезапуск PHP-FPM для применения изменений
echo "Перезапуск PHP-FPM..."
sudo systemctl restart php${PHP_VERSION}-fpm

if [ $? -eq 0 ]; then
    echo "✓ PHP-FPM успешно перезапущен"
else
    echo "⚠ Ошибка при перезапуске PHP-FPM, пробуем alternative команду"
    sudo systemctl restart php*-fpm
fi

# Перезапуск Apache для применения изменений
echo "Перезапуск Apache..."
sudo systemctl restart apache2

if [ $? -eq 0 ]; then
    echo "✓ Apache успешно перезапущен"
else
    echo "✗ Ошибка при перезапуске Apache"
    exit 1
fi

echo "Установка расширений завершена!"
echo "Теперь проверьте, работает ли Nextcloud: curl -I http://localhost"