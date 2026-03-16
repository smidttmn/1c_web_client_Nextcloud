#!/bin/bash
# Скрипт добавления mod_substitute для переписывания URL в ответах 1С

APACHE_CONFIG="/etc/apache2/sites-available/nextcloud-le-ssl.conf"

# Находим строку с ProxyPass /one_c_web_client_v3
LINE_NUM=$(grep -n "ProxyPass /one_c_web_client_v3" "$APACHE_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "✗ Не найден ProxyPass /one_c_web_client_v3"
    exit 1
fi

# Вставляем директивы ПОСЛЕ ProxyPass
cat >> /tmp/substitute_insert.txt << 'EOF'
    ProxyPassReverseCookieDomain 10.72.1.5 cloud.smidt.keenetic.pro
    
    # Переписывание URL в HTML ответе от 1С
    AddOutputFilterByType SUBSTITUTE text/html
    Substitute "s|href=\"/|href=\"/one_c_web_client_v3/|in"
    Substitute "s|src=\"/|src=\"/one_c_web_client_v3/|in"
EOF

# Вставляем после строки с ProxyPass
LINE_AFTER=$((LINE_NUM + 3))
sed -i "${LINE_AFTER}r /tmp/substitute_insert.txt" "$APACHE_CONFIG"
rm /tmp/substitute_insert.txt

echo "✓ mod_substitute добавлен"

# Проверка
echo "Проверка синтаксиса..."
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    echo "✓ Синтаксис корректен"
    systemctl restart apache2
    echo "✓ Apache перезапущен"
    echo ""
    echo "Готово! 1С должна работать правильно."
else
    echo "✗ Ошибка синтаксиса!"
    apache2ctl configtest
    exit 1
fi
