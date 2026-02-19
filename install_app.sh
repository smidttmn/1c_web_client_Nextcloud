#!/bin/bash
# Скрипт для установки приложения 1C WebClient в Nextcloud

echo "Установка приложения 1C WebClient в Nextcloud..."

# Проверяем, существует ли директория приложений
if [ ! -d "/var/www/nextcloud/apps/" ]; then
    echo "Ошибка: Директория /var/www/nextcloud/apps/ не найдена"
    exit 1
fi

# Копируем приложение в директорию приложений Nextcloud
if sudo cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client; then
    echo "Приложение успешно скопировано в /var/www/nextcloud/apps/one_c_web_client"
else
    echo "Ошибка: Не удалось скопировать приложение в директорию приложений Nextcloud"
    exit 1
fi

# Устанавливаем права доступа к файлам приложения
if sudo chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client; then
    echo "Права доступа к файлам приложения успешно установлены"
else
    echo "Предупреждение: Не удалось установить права доступа к файлам приложения"
fi

# Устанавливаем приложение через OCC
if sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client; then
    echo "Приложение успешно установлено в Nextcloud"
else
    echo "Ошибка: Не удалось установить приложение через OCC"
    exit 1
fi

# Включаем приложение (на случай, если оно не включился автоматически)
if sudo -u www-data php -f /var/www/nextcloud/occ app:enable one_c_web_client; then
    echo "Приложение успешно включено"
else
    echo "Ошибка: Не удалось включить приложение"
    exit 1
fi

echo "Установка приложения завершена успешно!"
echo "Теперь вы можете настроить список баз 1С через административный интерфейс Nextcloud"