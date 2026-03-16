#!/bin/bash
# ============================================================================
# one_c_web_client_v3 - ИНТЕРАКТИВНЫЙ УСТАНОВЩИК С АВТО-НАСТРОЙКОЙ
# Версия: 10.0.0 - УНИВЕРСАЛЬНАЯ НАСТРОЙКА ПРОКСИ (SSL + NON_SSL)
# ============================================================================
#
# ВАЖНО: Этот скрипт:
# - Автоматически проверяет ВСЕ зависимости
# - Сам настраивает Apache ПРАВИЛЬНО (SSL или без SSL)
# - НЕ ломает существующие настройки
# - Создаёт резервные копии
# - Проверяет каждый шаг
# - ГЛАВНОЕ: ProxyPass ДО всех исключений!
# ============================================================================

set -o pipefail

# ============================================================================
# ПЕРЕМЕННЫЕ
# ============================================================================
NEXTCLOUD_PATH=""
APACHE_CONFIG=""
APP_NAME="one_c_web_client_v3"
APP_VERSION="9.0.0"
BACKUP_DIR=""
declare -a ONE_C_SERVERS=()
declare -a ONE_C_PATHS=()

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Логирование
LOG_FILE="/tmp/one_c_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ============================================================================
# Функции вывода
# ============================================================================
print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client_v3 - ИНТЕРАКТИВНЫЙ УСТАНОВЩИК         ║"
    echo "║   Версия $APP_VERSION - ПОЛНАЯ АВТОМАТИЗАЦИЯ             ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() { echo -e "${YELLOW}[ШАГ $1] $2${NC}"; }
print_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
print_error() { echo -e "${RED}  ✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${CYAN}  ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}  ⚠ $1${NC}"; }

# ============================================================================
# Проверка прав
# ============================================================================
check_root() {
    print_step "1" "Проверка прав доступа"
    
    if [ "$EUID" -ne 0 ]; then
        print_error "Запустите скрипт от root (sudo ./install.sh)"
        exit 1
    fi
    print_success "Права root подтверждены"
}

# ============================================================================
# Поиск Nextcloud
# ============================================================================
find_nextcloud() {
    print_step "2" "Поиск Nextcloud"
    
    local nc_paths=(
        "/var/www/html/nextcloud"
        "/var/www/nextcloud"
        "/srv/www/nextcloud"
        "/opt/nextcloud"
    )
    
    for path in "${nc_paths[@]}"; do
        if [ -f "$path/occ" ]; then
            NEXTCLOUD_PATH="$path"
            print_success "Nextcloud найден: $NEXTCLOUD_PATH"
            return 0
        fi
    done
    
    print_error "Nextcloud не найден!"
    echo "Пожалуйста, укажите путь к Nextcloud:"
    read -p "Путь: " custom_path
    if [ -f "$custom_path/occ" ]; then
        NEXTCLOUD_PATH="$custom_path"
        print_success "Nextcloud найден: $NEXTCLOUD_PATH"
    else
        print_error "В указанном пути нет Nextcloud (файл occ не найден)"
        exit 1
    fi
}

# ============================================================================
# Поиск конфига Apache
# ============================================================================
find_apache_config() {
    print_step "3" "Поиск конфига Apache"

    local ssl_config="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
    local non_ssl_config="/etc/apache2/sites-available/nextcloud.conf"

    # Проверяем SSL конфигурацию
    if [ -f "$ssl_config" ] && grep -q "VirtualHost.*:443" "$ssl_config" 2>/dev/null; then
        APACHE_CONFIG="$ssl_config"
        print_success "Конфиг Apache найден: $APACHE_CONFIG (SSL)"
        return 0
    fi

    # Проверяем конфигурацию без SSL
    if [ -f "$non_ssl_config" ] && grep -q "VirtualHost" "$non_ssl_config" 2>/dev/null; then
        APACHE_CONFIG="$non_ssl_config"
        print_success "Конфиг Apache найден: $APACHE_CONFIG (NON_SSL)"
        return 0
    fi

    print_error "Конфиг Apache не найден!"
    exit 1
}

# ============================================================================
# Проверка модулей Apache
# ============================================================================
check_apache_modules() {
    print_step "4" "Проверка модулей Apache"
    
    local required_modules=("proxy" "proxy_http" "headers" "rewrite" "ssl" "substitute")
    local missing_modules=()
    
    for module in "${required_modules[@]}"; do
        if a2query -m "$module" 2>/dev/null; then
            print_success "Модуль $module: включён"
        else
            missing_modules+=("$module")
            print_warning "Модуль $module: отключён"
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        print_info "Включение отсутствующих модулей..."
        for module in "${missing_modules[@]}"; do
            if a2enmod "$module" 2>/dev/null; then
                print_success "Модуль $module включён"
            else
                print_error "Не удалось включить модуль $module"
            fi
        done
        print_info "Перезапустите Apache после установки модулей"
    fi
}

# ============================================================================
# Установка приложения
# ============================================================================
install_app() {
    print_step "5" "Установка приложения"
    
    local app_archive="$(dirname "$0")/app/one_c_web_client_v3.tar.gz"
    local app_dest="$NEXTCLOUD_PATH/apps/$APP_NAME"
    
    # Проверка архива
    if [ ! -f "$app_archive" ]; then
        print_error "Архив приложения не найден: $app_archive"
        exit 1
    fi
    
    print_info "Архив найден: $app_archive"
    
    # Удаляем старую версию
    if [ -d "$app_dest" ]; then
        print_warning "Старая версия приложения найдена"
        sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || true
        sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || true
        rm -rf "$app_dest"
        print_success "Старая версия удалена"
    fi
    
    # Распаковка
    print_info "Распаковка приложения..."
    mkdir -p "$app_dest"
    tar -xzf "$app_archive" -C "$app_dest" --strip-components=1
    
    # Права
    chown -R www-data:www-data "$app_dest"
    chmod -R 755 "$app_dest"
    print_success "Права установлены"
    
    # Установка через occ
    print_info "Установка приложения через occ..."
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:install "$APP_NAME" 2>/dev/null; then
        print_success "Приложение установлено"
    elif sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:enable "$APP_NAME" 2>/dev/null; then
        print_success "Приложение включено"
    else
        print_error "Не удалось установить приложение"
        exit 1
    fi
    
    # Очистка кэша
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:repair 2>/dev/null || true
    print_success "Кэш очищен"
}

# ============================================================================
# Интерактивное добавление серверов 1С
# ============================================================================
add_1c_servers() {
    print_step "6" "Добавление серверов 1С"
    
    echo ""
    print_info "═══════════════════════════════════════════════════════════"
    print_info "ДОБАВЛЕНИЕ СЕРВЕРОВ 1С"
    print_info "═══════════════════════════════════════════════════════════"
    echo ""
    print_warning "ВАЖНО: Если вы пропустите этот шаг, прокси НЕ будет настроен!"
    print_warning "Для добавления серверов позже потребуется ручная настройка через консоль."
    echo ""
    
    read -p "Добавить сервер 1С сейчас? [Y/n]: " add_now
    if [[ "$add_now" =~ ^[Nn]$ ]]; then
        print_info "Настройка прокси пропущена"
        return 0
    fi
    
    echo ""
    local server_num=1
    
    while true; do
        print_info "─── Сервер 1С #$server_num ───"
        echo ""
        
        # Название базы
        read -p "Название базы (например, Бухгалтерия): " db_name
        if [ -z "$db_name" ]; then
            print_error "Название не может быть пустым"
            continue
        fi
        
        # URL сервера 1С
        read -p "URL сервера 1С (например, https://10.72.1.5/sgtbuh): " one_c_url
        if [ -z "$one_c_url" ]; then
            print_error "URL не может быть пустым"
            continue
        fi
        
        # Проверка формата URL
        if [[ ! "$one_c_url" =~ ^https?:// ]]; then
            print_error "URL должен начинаться с http:// или https://"
            continue
        fi
        
        # Извлекаем базовый URL и путь
        local base_url=$(echo "$one_c_url" | sed 's|/\([^/]*\)$||')
        local base_path=$(echo "$one_c_url" | grep -oP '[^/]+$')
        
        # Добавляем слэш на конце если нет
        [[ ! "$base_path" =~ /$ ]] && base_path="$base_path/"
        
        # Сохраняем сервер
        ONE_C_SERVERS+=("$base_url")
        ONE_C_PATHS+=("$base_path")
        print_success "Сервер добавлен: $db_name → $base_url$base_path"
        
        echo ""
        read -p "Добавить ещё один сервер 1С? [y/N]: " add_more
        if [[ ! "$add_more" =~ ^[Yy]$ ]]; then
            break
        fi
        
        ((server_num++))
        echo ""
    done
    
    echo ""
    print_success "Добавлено серверов 1С: ${#ONE_C_SERVERS[@]}"
}

# ============================================================================
# Универсальная настройка Apache прокси (SSL + без SSL)
# ============================================================================
configure_apache_universal() {
    if [ ${#ONE_C_SERVERS[@]} -eq 0 ]; then
        print_warning "Серверы 1С не добавлены, настройка прокси пропущена"
        return 0
    fi

    print_step "7" "Автоматическая настройка Apache прокси"

    # Создаём резервную копию
    BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Определяем тип конфигурации (SSL или без SSL)
    local ssl_config="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
    local non_ssl_config="/etc/apache2/sites-available/nextcloud.conf"
    local active_config=""
    local config_type=""

    # Проверяем наличие SSL конфигурации
    if [ -f "$ssl_config" ] && grep -q "VirtualHost.*:443" "$ssl_config" 2>/dev/null; then
        active_config="$ssl_config"
        config_type="SSL"
        cp "$ssl_config" "$BACKUP_DIR/apache_ssl_config.backup"
        print_success "Обнаружена SSL конфигурация (порт 443)"
    elif [ -f "$non_ssl_config" ] && grep -q "VirtualHost" "$non_ssl_config" 2>/dev/null; then
        active_config="$non_ssl_config"
        config_type="NON_SSL"
        cp "$non_ssl_config" "$BACKUP_DIR/apache_config.backup"
        print_success "Обнаружена конфигурация без SSL (порт 80)"
    else
        print_error "Не найдена конфигурация Apache!"
        return 1
    fi

    print_info "Активная конфигурация: $active_config ($config_type)"

    # Проверяем, есть ли уже наши настройки
    if grep -q "one_c_web_client_v3 - Прокси" "$active_config" 2>/dev/null; then
        print_warning "Настройки прокси уже найдены"
        read -p "Пересоздать настройки прокси? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$active_config"
            print_success "Старые настройки удалены"
        else
            print_info "Настройка прокси пропущена"
            return 0
        fi
    fi

    # Определяем точку вставки в зависимости от типа конфигурации
    local insert_line=""
    if [ "$config_type" = "SSL" ]; then
        # Для SSL: после Include options-ssl-apache.conf
        insert_line=$(grep -n "Include.*/etc/letsencrypt/options-ssl-apache.conf" "$active_config" | head -1 | cut -d: -f1)
        if [ -z "$insert_line" ]; then
            # Альтернатива: после SSLCertificateKeyFile
            insert_line=$(grep -n "SSLCertificateKeyFile" "$active_config" | head -1 | cut -d: -f1)
        fi
    else
        # Для NON_SSL: после DocumentRoot или RewriteEngine
        insert_line=$(grep -n "DocumentRoot" "$active_config" | head -1 | cut -d: -f1)
        if [ -z "$insert_line" ]; then
            insert_line=$(grep -n "RewriteEngine" "$active_config" | head -1 | cut -d: -f1)
        fi
    fi

    if [ -z "$insert_line" ]; then
        print_error "Не найдена точка вставки конфигурации!"
        return 1
    fi

    # Извлекаем хост из URL первого сервера
    local first_server="${ONE_C_SERVERS[0]}"
    local server_host=$(echo "$first_server" | sed 's|https\?://||' | sed 's|/.*||')

    # Создаём файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << EOF

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено установщиком v$APP_VERSION)
    # ПРАВИЛЬНАЯ КОНФИГУРАЦИЯ: ProxyPass ДО всех исключений!
    # ===================================================================

EOF

    # Добавляем SSL настройки только для SSL конфигурации
    if [ "$config_type" = "SSL" ]; then
        cat >> "$directives_file" << EOF
    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

EOF
    fi

    # 1. ProxyPass для one_c_web_client_v3 (ОБЯЗАТЕЛЬНО ДО ИСКЛЮЧЕНИЙ!)
    cat >> "$directives_file" << EOF
    # 1. Прокси для one_c_web_client_v3 (ОБЯЗАТЕЛЬНО ДО ИСКЛЮЧЕНИЙ!)
    ProxyPass /one_c_web_client_v3 ${first_server}/ retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 ${first_server}/

    # 2. ProxyPassMatch для всех путей
    ProxyPassMatch ^/one_c_web_client_v3/(.*)$ ${first_server}/\$1

EOF

    # 3. Прокси для путей 1С (sgtbuh, zupnew и т.д.)
    for i in "${!ONE_C_SERVERS[@]}"; do
        local base_path="${ONE_C_PATHS[$i]}"
        # Убираем слэш на конце для ProxyPass
        base_path="${base_path%/}"
        local server_url="${ONE_C_SERVERS[$i]}"

        cat >> "$directives_file" << EOF
    # Прокси для путей 1С: ${base_path}
    ProxyPass ${base_path} ${server_url}${base_path}
    ProxyPassReverse ${base_path} ${server_url}${base_path}

EOF
    done

    # 4. ИСКЛЮЧЕНИЯ для статических файлов Nextcloud
    cat >> "$directives_file" << EOF
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

    # Вставляем директивы ПОСЛЕ найденной строки
    sed -i "${insert_line}r $directives_file" "$active_config"
    rm "$directives_file"

    print_success "Настройки прокси добавлены в $config_type конфигурацию"

    # Отключаем AllowOverride чтобы .htaccess не блокировал прокси
    print_info "Отключение AllowOverride для работы прокси..."
    sed -i 's/AllowOverride All/AllowOverride None/g' "$active_config"
    print_success "AllowOverride отключён"

    # Проверка синтаксиса
    print_info "Проверка синтаксиса Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -10
        print_info "Восстановление резервной копии..."
        if [ "$config_type" = "SSL" ]; then
            cp "$BACKUP_DIR/apache_ssl_config.backup" "$ssl_config"
        else
            cp "$BACKUP_DIR/apache_config.backup" "$non_ssl_config"
        fi
        return 1
    fi

    # Перезапуск Apache
    print_info "Перезапуск Apache..."
    if systemctl restart apache2; then
        print_success "Apache перезапущен"
    else
        print_error "Не удалось перезапустить Apache"
        return 1
    fi

    print_success "Прокси настроен для ${#ONE_C_SERVERS[@]} серверов 1С"
}

# ============================================================================
# Проверка установки
# ============================================================================
verify_installation() {
    print_step "8" "Проверка установки"
    
    # Проверка приложения
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:list 2>/dev/null | grep -q "$APP_NAME"; then
        print_success "Приложение $APP_NAME активно"
    else
        print_warning "Приложение $APP_NAME не найдено"
    fi
    
    # Проверка конфига Apache
    if [ -n "$APACHE_CONFIG" ]; then
        if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
            print_success "Конфигурация Apache корректна"
        else
            print_error "Ошибка в конфигурации Apache"
        fi
    fi
    
    # Проверка прокси
    if [ ${#ONE_C_SERVERS[@]} -gt 0 ]; then
        if grep -q "ProxyPass /one_c_web_client_v3" "$APACHE_CONFIG"; then
            print_success "ProxyPass настроен"
        else
            print_warning "ProxyPass не найден"
        fi
    fi
}

# ============================================================================
# Финальный отчёт
# ============================================================================
final_report() {
    print_header "Установка завершена!"
    
    echo ""
    echo "📋 Информация об установке:"
    echo ""
    echo "  Приложение: $APP_NAME v$APP_VERSION"
    echo "  Nextcloud:  $NEXTCLOUD_PATH"
    if [ -n "$APACHE_CONFIG" ]; then
        echo "  Apache:     $APACHE_CONFIG"
    fi
    echo "  Лог:        $LOG_FILE"
    echo ""
    
    if [ ${#ONE_C_SERVERS[@]} -gt 0 ]; then
        echo "📋 Настроено серверов 1С:"
        for i in "${!ONE_C_SERVERS[@]}"; do
            echo "  - ${ONE_C_PATHS[$i]} → ${ONE_C_SERVERS[$i]}"
        done
        echo ""
    else
        echo "⚠️  Прокси НЕ настроен!"
        echo ""
    fi
    
    echo "📋 Следующие шаги:"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://your-nextcloud-domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс (если не добавили при установке)"
    echo ""
    echo "3. Проверьте работу приложения:"
    echo "   https://your-nextcloud-domain/index.php/apps/$APP_NAME/"
    echo ""
    echo "4. Очистите кэш браузера: Ctrl+Shift+R"
    echo ""
    
    print_success "Установка завершена!"
}

# ============================================================================
# Основная функция
# ============================================================================
main() {
    print_header

    echo "Этот скрипт:"
    echo "  1. Проверит права и зависимости"
    echo "  2. Найдёт Nextcloud и Apache конфиг (АВТОМАТИЧЕСКИ)"
    echo "  3. Проверит модули Apache"
    echo "  4. Установит приложение"
    echo "  5. Интерактивно добавит серверы 1С"
    echo "  6. Автоматически настроит Apache прокси:"
    echo "     - ОПРЕДЕЛИТ тип конфигурации (SSL или NON_SSL)"
    echo "     - ProxyPass ДО всех исключений (ПРАВИЛЬНО!)"
    echo "     - ProxyPassMatch для всех путей"
    echo "     - mod_substitute для переписывания URL"
    echo "     - AllowOverride None для работы прокси"
    echo "  7. Проверит работу после установки"
    echo ""
    echo "🎯 РЕЗУЛЬТАТ: 1С работает сразу после установки!"
    echo ""
    
    read -p "Продолжить установку? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Установка отменена"
        exit 0
    fi
    
    echo ""
    
    # Запуск этапов
    check_root
    echo ""
    
    find_nextcloud
    echo ""
    
    find_apache_config
    echo ""
    
    check_apache_modules
    echo ""
    
    install_app
    echo ""
    
    add_1c_servers
    echo ""

    configure_apache_universal
    echo ""

    verify_installation
    echo ""
    
    final_report
}

# Запуск
main "$@"
