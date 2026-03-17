#!/bin/bash
# ============================================================================
# one_c_web_client_v3 - БЫСТРАЯ НАСТРОЙКА APACHE ПРОКСИ
# Версия: 1.0.0 - УНИВЕРСАЛЬНЫЙ СКРИПТ (SSL + без SSL)
# ============================================================================
#
# Этот скрипт:
# - Автоматически определяет тип конфигурации (SSL или без SSL)
# - Настраивает прокси ПРАВИЛЬНО (ProxyPass ДО исключений)
# - НЕ ломает существующие настройки
# - Создаёт резервные копии
# ============================================================================

set -o pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Логирование
LOG_FILE="/tmp/one_c_proxy_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client_v3 - НАСТРОЙКА ПРОКСИ                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() { echo -e "${YELLOW}[ШАГ $1] $2${NC}"; }
print_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
print_error() { echo -e "${RED}  ✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${CYAN}  ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}  ⚠ $1${NC}"; }

# Проверка прав
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Запустите скрипт от root (sudo ./setup_apache_proxy.sh)"
        exit 1
    fi
    print_success "Права root подтверждены"
}

# Проверка модулей Apache
check_apache_modules() {
    print_step "1" "Проверка модулей Apache"

    local required_modules=("proxy" "proxy_http" "headers" "rewrite" "substitute")
    local missing_modules=()

    for module in "${required_modules[@]}"; do
        if a2query -m "$module" 2>/dev/null; then
            print_success "Модуль $module: включён"
        else
            missing_modules+=("$module")
        fi
    done

    if [ ${#missing_modules[@]} -gt 0 ]; then
        print_info "Включение отсутствующих модулей..."
        for module in "${missing_modules[@]}"; do
            a2enmod "$module" 2>/dev/null && print_success "Модуль $module включён"
        done
        print_info "Перезапустите Apache после установки модулей"
    fi
}

# Определение конфигурации
detect_config() {
    print_step "2" "Определение конфигурации Apache"

    local ssl_config="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
    local non_ssl_config="/etc/apache2/sites-available/nextcloud.conf"

    if [ -f "$ssl_config" ] && grep -q "VirtualHost.*:443" "$ssl_config" 2>/dev/null; then
        ACTIVE_CONFIG="$ssl_config"
        CONFIG_TYPE="SSL"
        print_success "Обнаружена SSL конфигурация (порт 443)"
        return 0
    elif [ -f "$non_ssl_config" ] && grep -q "VirtualHost" "$non_ssl_config" 2>/dev/null; then
        ACTIVE_CONFIG="$non_ssl_config"
        CONFIG_TYPE="NON_SSL"
        print_success "Обнаружена конфигурация без SSL (порт 80)"
        return 0
    else
        print_error "Не найдена конфигурация Apache!"
        exit 1
    fi
}

# Получение списка серверов 1С из Nextcloud
get_1c_servers() {
    print_step "3" "Получение списка серверов 1С"

    # Пытаемся получить из Nextcloud
    local nc_paths=("/var/www/html/nextcloud" "/var/www/nextcloud" "/srv/www/nextcloud" "/opt/nextcloud")
    local nc_path=""

    for path in "${nc_paths[@]}"; do
        if [ -f "$path/occ" ]; then
            nc_path="$path"
            break
        fi
    done

    if [ -n "$nc_path" ]; then
        DATABASES=$(sudo -u www-data php "$nc_path/occ config:app:get one_c_web_client_v3 databases 2>/dev/null || echo \"[]\"")
        if [ "$DATABASES" != "[]" ] && [ -n "$DATABASES" ]; then
            # Извлекаем URL из JSON
            SERVER_URL=$(echo "$DATABASES" | grep -oP '"url"\s*:\s*"\K[^"]+' | head -1 | sed 's|/$||')
            if [ -n "$SERVER_URL" ]; then
                ONE_C_SERVER="$SERVER_URL"
                print_success "Сервер 1С получен из Nextcloud: $ONE_C_SERVER"
                return 0
            fi
        fi
    fi

    # Если не получили из Nextcloud, спрашиваем вручную
    print_warning "Не удалось получить сервер 1С из Nextcloud"
    read -p "Введите URL сервера 1С (например, https://10.72.1.5/sgtbuh): " ONE_C_SERVER

    if [ -z "$ONE_C_SERVER" ]; then
        print_error "URL не может быть пустым"
        exit 1
    fi

    if [[ ! "$ONE_C_SERVER" =~ ^https?:// ]]; then
        print_error "URL должен начинаться с http:// или https://"
        exit 1
    fi

    print_success "Сервер 1С: $ONE_C_SERVER"
}

# Настройка прокси
configure_proxy() {
    print_step "4" "Настройка Apache прокси"

    # Создаём резервную копию
    BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$ACTIVE_CONFIG" "$BACKUP_DIR/apache_config.backup"
    print_success "Резервная копия: $BACKUP_DIR/apache_config.backup"

    # Удаляем старые настройки
    if grep -q "one_c_web_client_v3 - Прокси" "$ACTIVE_CONFIG" 2>/dev/null; then
        print_warning "Настройки прокси уже найдены"
        sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$ACTIVE_CONFIG"
        print_success "Старые настройки удалены"
    fi

    # Определяем точку вставки
    local insert_line=""
    if [ "$CONFIG_TYPE" = "SSL" ]; then
        insert_line=$(grep -n "Include.*/etc/letsencrypt/options-ssl-apache.conf" "$ACTIVE_CONFIG" | head -1 | cut -d: -f1)
        if [ -z "$insert_line" ]; then
            insert_line=$(grep -n "SSLCertificateKeyFile" "$ACTIVE_CONFIG" | head -1 | cut -d: -f1)
        fi
    else
        insert_line=$(grep -n "DocumentRoot" "$ACTIVE_CONFIG" | head -1 | cut -d: -f1)
        if [ -z "$insert_line" ]; then
            insert_line=$(grep -n "RewriteEngine" "$ACTIVE_CONFIG" | head -1 | cut -d: -f1)
        fi
    fi

    if [ -z "$insert_line" ]; then
        print_error "Не найдена точка вставки!"
        exit 1
    fi

    # Извлекаем хост и путь
    local server_host=$(echo "$ONE_C_SERVER" | sed 's|https\?://||' | sed 's|/.*||')
    local server_path=$(echo "$ONE_C_SERVER" | grep -oP '[^/]+$' | sed 's|/$||')

    # Создаём файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено скриптом)
    # ПРАВИЛЬНАЯ КОНФИГУРАЦИЯ: ProxyPass ДО всех исключений!
    # ===================================================================

EOF

    # SSL настройки только для SSL
    if [ "$CONFIG_TYPE" = "SSL" ]; then
        cat >> "$directives_file" << 'EOF'
    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

EOF
    fi

    # ProxyPass для one_c_web_client_v3
    cat >> "$directives_file" << EOF
    # 1. Прокси для one_c_web_client_v3 (ОБЯЗАТЕЛЬНО ДО ИСКЛЮЧЕНИЙ!)
    ProxyPass /one_c_web_client_v3 ${ONE_C_SERVER}/ retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 ${ONE_C_SERVER}/

    # 2. ProxyPassMatch для всех путей
    ProxyPassMatch ^/one_c_web_client_v3/(.*)\$ ${ONE_C_SERVER}/\$1

    # 3. Прокси для путей 1С
    ProxyPass /${server_path} ${ONE_C_SERVER}
    ProxyPassReverse /${server_path} ${ONE_C_SERVER}

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
    ProxyPassReverseCookieDomain ${server_host} $(hostname -f 2>/dev/null || hostname)
    ProxyPassReverseCookiePath / /

    # 6. mod_substitute для переписывания URL
    AddOutputFilterByType SUBSTITUTE text/html
    Substitute s|href=\"/|href=\"/one_c_web_client_v3/|in
    Substitute s|src=\"/|src=\"/one_c_web_client_v3/|in

    # 7. Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy \"frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;\"

    # ===================================================================
    # END one_c_web_client_v3
    # ===================================================================

EOF

    # Вставляем
    sed -i "${insert_line}r $directives_file" "$ACTIVE_CONFIG"
    rm "$directives_file"

    print_success "Настройки прокси добавлены"

    # Отключаем AllowOverride
    sed -i 's/AllowOverride All/AllowOverride None/g' "$ACTIVE_CONFIG"
    print_success "AllowOverride отключён"
}

# Проверка и перезапуск
restart_apache() {
    print_step "5" "Проверка и перезапуск Apache"

    print_info "Проверка синтаксиса..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис корректен"
    else
        print_error "Ошибка синтаксиса!"
        apache2ctl configtest 2>&1 | head -10
        print_info "Восстановление резервной копии..."
        cp "$BACKUP_DIR/apache_config.backup" "$ACTIVE_CONFIG"
        exit 1
    fi

    print_info "Перезапуск Apache..."
    if systemctl restart apache2; then
        print_success "Apache перезапущен"
    else
        print_error "Не удалось перезапустить Apache"
        exit 1
    fi
}

# Финальный отчёт
final_report() {
    print_header

    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    ГОТОВО!                                ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo ""
    echo "📋 Информация:"
    echo ""
    echo "  Конфигурация: $CONFIG_TYPE ($ACTIVE_CONFIG)"
    echo "  Сервер 1С:    $ONE_C_SERVER"
    echo "  Резервная копия: $BACKUP_DIR/apache_config.backup"
    echo "  Лог:          $LOG_FILE"
    echo ""
    echo "📋 Следующие шаги:"
    echo ""
    echo "1. Обновите страницу в браузере: Ctrl+Shift+R"
    echo "2. Нажмите на кнопку базы 1С"
    echo "3. 1С должна открыться через прокси"
    echo ""

    if [ "$CONFIG_TYPE" = "SSL" ]; then
        echo "⚠️  Если 1С не загружается, проверьте:"
        echo "   - HTTPS на сервере 1С"
        echo "   - Самоподписанные сертификаты (примите в браузере)"
        echo ""
    fi

    print_success "Настройка завершена!"
}

# Основная функция
main() {
    print_header

    echo "Этот скрипт:"
    echo "  1. Проверит права и модули Apache"
    echo "  2. Определит тип конфигурации (SSL/NON_SSL)"
    echo "  3. Получит сервер 1С из Nextcloud или спросит вручную"
    echo "  4. Настроит прокси ПРАВИЛЬНО:"
    echo "     - ProxyPass ДО исключений"
    echo "     - ProxyPassMatch для путей"
    echo "     - mod_substitute для URL"
    echo "     - AllowOverride None"
    echo "  5. Проверит и перезапустит Apache"
    echo ""

    read -p "Продолжить настройку прокси? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Настройка отменена"
        exit 0
    fi

    echo ""

    check_root
    echo ""

    check_apache_modules
    echo ""

    detect_config
    echo ""

    get_1c_servers
    echo ""

    configure_proxy
    echo ""

    restart_apache
    echo ""

    final_report
}

main "$@"
