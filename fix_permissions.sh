#!/bin/bash
# Скрипт для исправления прав доступа к файлам Nextcloud

echo "Исправление прав доступа к файлам Nextcloud..."

# Проверяем, существует ли директория Nextcloud
if [ ! -d "/var/www/nextcloud" ]; then
    echo "Ошибка: Директория /var/www/nextcloud не найдена"
    exit 1
fi

# Устанавливаем владельца для всех файлов и директорий Nextcloud
echo "Устанавливаем владельца www-data для файлов Nextcloud..."
sudo chown -R www-data:www-data /var/www/nextcloud/

if [ $? -eq 0 ]; then
    echo "✓ Права владельца успешно установлены"
else
    echo "✗ Ошибка при установке владельца файлов"
    exit 1
fi

# Устанавливаем правильные права доступа к файлам
echo "Устанавливаем правильные права доступа..."

# Файлы должны иметь права 644 (чтение и запись для владельца, только чтение для группы и остальных)
find /var/www/nextcloud -type f -exec sudo chmod 644 {} \;

# Директории должны иметь права 755 (чтение, запись и выполнение для владельца, чтение и выполнение для группы и остальных)
find /var/www/nextcloud -type d -exec sudo chmod 755 {} \;

# Делаем исключения для специфичных директорий
sudo chmod 770 /var/www/nextcloud/data 2>/dev/null || echo "Директория data может не существовать или не требовать особых прав"
sudo chmod 770 /var/www/nextcloud/config 2>/dev/null || echo "Директория config может не требовать особых прав"
sudo chmod 770 /var/www/nextcloud/apps 2>/dev/null || echo "Директория apps может не требовать особых прав"

# Устанавливаем особые права для важных файлов
sudo chmod 640 /var/www/nextcloud/config/config.php 2>/dev/null || echo "Файл config.php может не требовать особых прав"

echo "✓ Права доступа установлены"

# Перезапускаем веб-сервер для применения изменений
echo "Перезапускаем Apache..."
sudo systemctl restart apache2

if [ $? -eq 0 ]; then
    echo "✓ Apache успешно перезапущен"
else
    echo "✗ Ошибка при перезапуске Apache"
fi

# Проверяем, работает ли теперь Nextcloud
echo "Проверяем доступность Nextcloud..."
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
fi

echo "Исправление прав доступа завершено!"