#!/bin/bash
# ============================================================================
# one_c_web_client_v3 - Универсальный интерактивный установщик
# Версия: 7.0.0 - С интерактивным добавлением серверов 1С
# ============================================================================
# 
# ВАЖНО: Этот скрипт НЕ ломает существующие настройки:
# - SSL сертификаты НЕ трогаются
# - Существующие настройки Apache СОХРАНЯЮТСЯ
# - Конфигурация Nextcloud НЕ изменяется
#
# Скрипт:
# - Копирует файлы приложения
# - Устанавливает приложение через occ
# - Интерактивно добавляет серверы 1С
# - Настраивает ProxyPass для каждого сервера
# ============================================================================

set -o pipefail

# ============================================================================
# ПЕРЕМЕННЫЕ
# ============================================================================
NEXTCLOUD_PATH=""
APACHE_CONFIG=""
APP_NAME="one_c_web_client_v3"
APP_VERSION="7.0.0"
BACKUP_DIR=""
declare -a ONE_C_SERVERS=()

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
    echo "║   one_c_web_client_v3 - Интерактивный установщик         ║"
    echo "║   Версия $APP_VERSION - С добавлением серверов 1С        ║"
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
    print_step "1" "Поиск Nextcloud"
    
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
    print_step "2" "Поиск конфига Apache"
    
    local config_paths=(
        "/etc/apache2/sites-available/nextcloud.conf"
        "/etc/apache2/sites-available/nextcloud-le-ssl.conf"
        "/etc/apache2/sites-enabled/nextcloud.conf"
        "/etc/apache2/sites-enabled/000-default-le-ssl.conf"
    )
    
    for config in "${config_paths[@]}"; do
        if [ -f "$config" ] && grep -q "VirtualHost.*:443" "$config" 2>/dev/null; then
            APACHE_CONFIG="$config"
            print_success "Конфиг Apache найден: $APACHE_CONFIG"
            return 0
        fi
    done
    
    print_error "Конфиг Apache не найден!"
    exit 1
}

# ============================================================================
# Проверка модулей Apache
# ============================================================================
check_apache_modules() {
    print_step "3" "Проверка модулей Apache"
    
    local required_modules=("proxy" "proxy_http" "headers" "rewrite" "ssl")
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
            a2enmod "$module" 2>/dev/null && print_success "Модуль $module включён"
        done
    fi
}

# ============================================================================
# Установка приложения
# ============================================================================
install_app() {
    print_step "4" "Установка приложения"
    
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
    print_step "5" "Добавление серверов 1С"
    
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
        print_info "Для добавления серверов позже выполните:"
        echo "   sudo nano $APACHE_CONFIG"
        echo "   # Добавьте ProxyPass для каждого сервера 1С"
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
        
        # Сохраняем сервер
        ONE_C_SERVERS+=("$one_c_url")
        print_success "Сервер добавлен: $db_name → $one_c_url"
        
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
# Настройка Apache прокси (НЕ ЛОМАЕТ SSL!)
# ============================================================================
configure_apache_proxy() {
    if [ ${#ONE_C_SERVERS[@]} -eq 0 ]; then
        print_warning "Серверы 1С не добавлены, настройка прокси пропущена"
        return 0
    fi
    
    print_step "6" "Настройка Apache прокси"
    
    # Создаём резервную копию (НЕ ТРОГАЕМ SSL!)
    BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
    print_success "Резервная копия создана: $BACKUP_DIR/apache_config.backup"
    
    # Проверяем, есть ли уже наши настройки
    if grep -q "one_c_web_client_v3 - Прокси" "$APACHE_CONFIG" 2>/dev/null; then
        print_warning "Настройки прокси уже найдены"
        read -p "Пересоздать настройки прокси? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$APACHE_CONFIG"
            print_success "Старые настройки удалены"
        else
            print_info "Настройка прокси пропущена"
            return 0
        fi
    fi
    
    # Находим </VirtualHost>
    local vhost_line=$(grep -n "</VirtualHost>" "$APACHE_CONFIG" | head -1 | cut -d: -f1)
    
    if [ -z "$vhost_line" ]; then
        print_error "Не найден закрывающий тег </VirtualHost>"
        return 0
    fi
    
    # Создаём файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено установщиком)
    # ВАЖНО: Эти настройки НЕ ломают SSL конфигурацию!
    # ===================================================================

    # SSL Proxy Settings (НЕ ИЗМЕНЯТЬ если уже настроено!)
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

    # Добавляем ProxyPass для каждого сервера
    for server in "${ONE_C_SERVERS[@]}"; do
        # Извлекаем базовый URL (без пути)
        local base_url=$(echo "$server" | sed 's|/\([^/]*\)$||')
        
        cat >> "$directives_file" << EOF
    # Прокси для 1С: $base_url
    ProxyPass /one_c_web_client_v3 $base_url/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 $base_url/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

EOF
    done
    
    # Добавляем CSP
    cat >> "$directives_file" << 'EOF'
    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # END one_c_web_client_v3
    # ===================================================================

EOF

    # Вставляем директивы перед </VirtualHost>
    local line_before=$((vhost_line - 1))
    sed -i "${line_before}r $directives_file" "$APACHE_CONFIG"
    rm "$directives_file"
    
    print_success "Настройки прокси добавлены для ${#ONE_C_SERVERS[@]} серверов"
    
    # Проверка синтаксиса
    print_info "Проверка синтаксиса Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -10
        print_info "Восстановление резервной копии..."
        cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
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
}

# ============================================================================
# Проверка установки
# ============================================================================
verify_installation() {
    print_step "7" "Проверка установки"
    
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
        for server in "${ONE_C_SERVERS[@]}"; do
            echo "  - $server"
        done
        echo ""
    else
        echo "⚠️  Прокси НЕ настроен!"
        echo ""
        echo "Для добавления серверов 1С выполните:"
        echo "  1. Откройте конфиг: sudo nano $APACHE_CONFIG"
        echo "  2. Добавьте перед </VirtualHost>:"
        echo ""
        echo "    # Прокси для 1С"
        echo "    SSLProxyEngine on"
        echo "    ProxyPass /one_c_web_client_v3 https://YOUR_1C_SERVER/one_c_web_client_v3"
        echo "    ProxyPassReverse /one_c_web_client_v3 https://YOUR_1C_SERVER/one_c_web_client_v3"
        echo ""
        echo "  3. Проверьте: sudo apache2ctl configtest"
        echo "  4. Перезапустите: sudo systemctl restart apache2"
        echo ""
    fi
    
    echo "📋 Следующие шаги:"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://your-nextcloud-domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс"
    echo ""
    echo "3. Проверьте работу приложения:"
    echo "   https://your-nextcloud-domain/index.php/apps/$APP_NAME/"
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
    echo "  2. Найдёт Nextcloud и Apache конфиг"
    echo "  3. Проверит модули Apache"
    echo "  4. Установит приложение"
    echo "  5. Интерактивно добавит серверы 1С"
    echo "  6. Настроит ProxyPass (НЕ ЛОМАЯ SSL!)"
    echo "  7. Проверит работу после установки"
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
    
    configure_apache_proxy
    echo ""
    
    verify_installation
    echo ""
    
    final_report
}

# Запуск
main "$@"
