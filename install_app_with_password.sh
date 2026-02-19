#!/bin/bash
# Скрипт для установки приложения one_c_web_client в Nextcloud

# Пароль для sudo
PASSWORD="Apple0589"

echo "Начинаем установку приложения one_c_web_client в Nextcloud..."

# Копируем приложение в директорию приложений Nextcloud
echo "$PASSWORD" | sudo -S cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client
if [ $? -eq 0 ]; then
    echo "✓ Приложение скопировано в директорию приложений"
else
    echo "✗ Ошибка при копировании приложения"
    exit 1
fi

# Устанавливаем правильные права доступа
echo "$PASSWORD" | sudo -S chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client
if [ $? -eq 0 ]; then
    echo "✓ Права доступа к приложению установлены"
else
    echo "✗ Ошибка при установке прав доступа к приложению"
    exit 1
fi

# Устанавливаем приложение через OCC
sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client
if [ $? -eq 0 ]; then
    echo "✓ Приложение one_c_web_client успешно установлено"
else
    echo "⚠ Ошибка при установке приложения, пробуем включить"
    sudo -u www-data php -f /var/www/nextcloud/occ app:enable one_c_web_client
    if [ $? -eq 0 ]; then
        echo "✓ Приложение one_c_web_client успешно включено"
    else
        echo "✗ Ошибка при включении приложения"
        exit 1
    fi
fi

echo "Установка приложения завершена успешно!"
echo "Теперь вы можете настроить список баз 1С через административный интерфейс Nextcloud"