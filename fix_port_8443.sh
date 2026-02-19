#!/bin/bash
# Скрипт добавляет порт 8443 в конфигурацию Apache и перезапускает его

echo "Добавляем порт 8443 в /etc/apache2/ports.conf..."

# Проверяем, есть ли уже Listen 8443
if grep -q "Listen 8443" /etc/apache2/ports.conf; then
    echo "Порт 8443 уже настроен в ports.conf"
else
    # Добавляем Listen 8443
    echo "Listen 8443" >> /etc/apache2/ports.conf
    echo "Порт 8443 добавлен в ports.conf"
fi

# Проверяем конфигурацию
echo "Проверка конфигурации Apache..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "Конфигурация в порядке. Перезапускаем Apache..."
    systemctl restart apache2
    echo "Apache перезапущен"
    
    # Проверяем, слушает ли порт 8443
    sleep 2
    if ss -tlnp | grep -q ":8443"; then
        echo "✓ Порт 8443 успешно открыт"
    else
        echo "✗ Порт 8443 не открылся. Проверьте логи Apache"
        exit 1
    fi
else
    echo "✗ Ошибка в конфигурации Apache"
    exit 1
fi

echo "Готово!"
