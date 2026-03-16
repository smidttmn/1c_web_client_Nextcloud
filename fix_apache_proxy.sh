#!/bin/bash
# Скрипт добавления ProxyPass для 1С в правильное место Apache конфига

APACHE_CONFIG="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"

# Создаём резервную копию
mkdir -p "$BACKUP_DIR"
cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
echo "✓ Резервная копия: $BACKUP_DIR/apache_config.backup"

# Находим строку с <Directory /var/www/nextcloud/>
LINE_NUM=$(grep -n "<Directory /var/www/nextcloud/>" "$APACHE_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "✗ Не найдено <Directory /var/www/nextcloud/>"
    exit 1
fi

# Вставляем ProxyPass ПЕРЕД <Directory>
cat >> /tmp/proxy_insert.txt << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено скриптом)
    # ВАЖНО: Должно быть ДО всех ProxyPass с !
    # ===================================================================
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    ProxyPass /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # END one_c_web_client_v3
    # ===================================================================

EOF

# Вставляем перед <Directory>
LINE_BEFORE=$((LINE_NUM - 1))
sed -i "${LINE_BEFORE}r /tmp/proxy_insert.txt" "$APACHE_CONFIG"
rm /tmp/proxy_insert.txt

echo "✓ ProxyPass добавлен"

# Проверка
echo "Проверка синтаксиса..."
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    echo "✓ Синтаксис корректен"
    systemctl restart apache2
    echo "✓ Apache перезапущен"
    echo ""
    echo "Готово! 1С должна работать через прокси."
else
    echo "✗ Ошибка синтаксиса!"
    apache2ctl configtest
    echo "Восстановление резервной копии..."
    cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
    exit 1
fi
