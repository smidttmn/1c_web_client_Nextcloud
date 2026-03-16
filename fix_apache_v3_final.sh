#!/bin/bash
# ============================================================================
# Исправление Apache конфигурации для one_c_web_client_v3
# ПРАВИЛЬНАЯ ВЕРСИЯ - ProxyPass ДО всех исключений
# ============================================================================

set -e

APACHE_CONFIG="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

if [ "$EUID" -ne 0 ]; then
    print_error "Запустите от root (sudo ./fix_apache_v3_final.sh)"
    exit 1
fi

print_info "Исправление конфигурации Apache для one_c_web_client_v3"

# Резервная копия
mkdir -p "$BACKUP_DIR"
cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
print_success "Резервная копия: $BACKUP_DIR/apache_config.backup"

# Удаляем старые настройки one_c_web_client_v3
print_info "Удаление старых настроек прокси..."
sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$APACHE_CONFIG"
print_success "Старые настройки удалены"

# Находим строку с Include /etc/letsencrypt/options-ssl-apache.conf
INCLUDE_LINE=$(grep -n "Include.*/etc/letsencrypt/options-ssl-apache.conf" "$APACHE_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$INCLUDE_LINE" ]; then
    print_error "Не найдено Include options-ssl-apache.conf"
    exit 1
fi

# Создаём файл с ПРАВИЛЬНОЙ конфигурацией
DIRECTIVES_FILE=$(mktemp)
cat > "$DIRECTIVES_FILE" << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (ПРАВИЛЬНАЯ ВЕРСИЯ)
    # ВАЖНО: ProxyPass должен быть ДО всех исключений!
    # ===================================================================

    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # 1. ProxyPass для one_c_web_client_v3 (ОБЯЗАТЕЛЬНО ДО ИСКЛЮЧЕНИЙ!)
    ProxyPass /one_c_web_client_v3 https://10.72.1.5/ retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 https://10.72.1.5/

    # 2. ProxyPassMatch для всех путей
    ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1

    # 3. Прокси для путей 1С (sgtbuh, zupnew и т.д.)
    ProxyPass /sgtbuh https://10.72.1.5/sgtbuh
    ProxyPassReverse /sgtbuh https://10.72.1.5/sgtbuh

    ProxyPass /zupnew https://10.72.1.5/zupnew
    ProxyPassReverse /zupnew https://10.72.1.5/zupnew

    # 4. ИСКЛЮЧЕНИЯ для статических файлов Nextcloud
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

    # 5. Переписывание куки
    ProxyPassReverseCookieDomain 10.72.1.5 cloud.smidt.keenetic.pro
    ProxyPassReverseCookiePath / /

    # 6. mod_substitute для переписывания URL в HTML ответе от 1С
    AddOutputFilterByType SUBSTITUTE text/html
    Substitute "s|href=\"/|href=\"/one_c_web_client_v3/|in"
    Substitute "s|src=\"/|src=\"/one_c_web_client_v3/|in"

    # 7. Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # END one_c_web_client_v3
    # ===================================================================

EOF

# Вставляем ПОСЛЕ строки с Include
sed -i "${INCLUDE_LINE}r $DIRECTIVES_FILE" "$APACHE_CONFIG"
rm "$DIRECTIVES_FILE"

print_success "Конфигурация обновлена"

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

print_success ""
print_success "═══════════════════════════════════════════════════════════"
print_success "КОНФИГУРАЦИЯ ИСПРАВЛЕНА!"
print_success "═══════════════════════════════════════════════════════════"
print_success ""
print_info "Теперь 1С должна работать через прокси."
print_info "Обновите страницу в браузере: Ctrl+Shift+R"
