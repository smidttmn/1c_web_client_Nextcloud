#!/bin/bash
# ============================================================================
# Настройка Apache прокси для one_c_web_client_v3
# Автоматически добавляет ProxyPass для каждого URL базы 1С
# ============================================================================

set -e

NC_APPS_PATH="/var/www/html/nextcloud/apps/one_c_web_client_v3"
APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    print_error "Запустите от root (sudo ./setup_apache_proxy.sh)"
    exit 1
fi

print_info "Настройка Apache прокси для one_c_web_client_v3"

# Получаем список URL баз данных из Nextcloud
print_info "Получение списка баз 1С из Nextcloud..."
DATABASES=$(sudo -u www-data php /var/www/html/nextcloud/occ config:app:get one_c_web_client_v3 databases 2>/dev/null || echo "[]")

if [ "$DATABASES" = "[]" ] || [ -z "$DATABASES" ]; then
    print_error "Базы 1С не настроены. Настройте через админ-панель Nextcloud"
    exit 1
fi

# Создаём резервную копию
mkdir -p "$BACKUP_DIR"
cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
print_success "Резервная копия: $BACKUP_DIR/apache_config.backup"

# Извлекаем уникальные хосты из URL баз данных
HOSTS=$(echo "$DATABASES" | grep -oP '"url"\s*:\s*"\K[^"]+' | sed 's|/$||' | grep -oP 'https?://[^/]+' | sort -u)

if [ -z "$HOSTS" ]; then
    print_error "Не удалось извлечь URL баз данных"
    exit 1
fi

print_info "Найдены хосты 1С:"
echo "$HOSTS"

# Удаляем старые ProxyPass для one_c_web_client
print_info "Удаление старых настроек прокси..."
sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$APACHE_CONFIG"

# Добавляем новые ProxyPass для каждого хоста
print_info "Добавление новых настроек прокси..."

# Находим строку с </VirtualHost>
VHOST_LINE=$(grep -n "</VirtualHost>" "$APACHE_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$VHOST_LINE" ]; then
    print_error "Не найден закрывающий тег </VirtualHost>"
    exit 1
fi

# Создаём файл с директивами
DIRECTIVES_FILE=$(mktemp)
cat > "$DIRECTIVES_FILE" << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено скриптом)
    # ===================================================================

    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # Исключения для статических файлов Nextcloud
    ProxyPass /core !
    ProxyPass /apps !
    ProxyPass /dist !
    ProxyPass /js !
    ProxyPass /css !
    ProxyPass /l10n !
    ProxyPass /index.php !
    ProxyPass /loleaflet !
    ProxyPass /browser !
    ProxyPass /hosting !
    ProxyPass /cool !

EOF

# Добавляем ProxyPass для каждого хоста
while IFS= read -r host; do
    if [ -n "$host" ]; then
        cat >> "$DIRECTIVES_FILE" << EOF
    # Прокси для 1С: $host
    ProxyPass /one_c_web_client_v3 $host/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 $host/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

EOF
    fi
done <<< "$HOSTS"

# Добавляем CSP
cat >> "$DIRECTIVES_FILE" << 'EOF'
    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # END one_c_web_client_v3
    # ===================================================================

EOF

# Вставляем директивы перед </VirtualHost>
LINE_BEFORE=$((VHOST_LINE - 1))
sed -i "${LINE_BEFORE}r $DIRECTIVES_FILE" "$APACHE_CONFIG"
rm "$DIRECTIVES_FILE"

print_success "Конфигурация прокси добавлена"

# Проверка синтаксиса
print_info "Проверка синтаксиса Apache..."
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    print_success "Синтаксис Apache корректен"
else
    print_error "Ошибка синтаксиса Apache!"
    apache2ctl configtest 2>&1 | head -10
    print_info "Восстановление резервной копии..."
    cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
    exit 1
fi

# Перезапуск Apache
print_info "Перезапуск Apache..."
if systemctl restart apache2; then
    print_success "Apache перезапущен"
else
    print_error "Не удалось перезапустить Apache"
    exit 1
fi

print_success "Настройка завершена!"
print_info "Резервная копия: $BACKUP_DIR/apache_config.backup"
