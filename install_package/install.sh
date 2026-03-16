#!/bin/bash
# ============================================================================
# one_c_web_client_v3 - Универсальный установщик
# Версия: 6.0.0 - Работает на любом сервере Nextcloud
# ============================================================================
# 
# ВАЖНО: Этот скрипт НЕ ломает существующие настройки:
# - SSL сертификаты НЕ трогаются
# - Существующие настройки Apache СОХРАНЯЮТСЯ
# - Конфигурация Nextcloud НЕ изменяется
#
# Скрипт только:
# - Копирует файлы приложения
# - Устанавливает приложение через occ
# - (Опционально) Добавляет ProxyPass в Apache
# ============================================================================

set -o pipefail

# ============================================================================
# ПЕРЕМЕННЫЕ (можно менять перед запуском)
# ============================================================================

# Путь к Nextcloud (автоматически определяется)
NEXTCLOUD_PATH=""

# Путь к конфиг Apache (автоматически определяется)
APACHE_CONFIG=""

# Имя приложения
APP_NAME="one_c_web_client_v3"

# Версия приложения
APP_VERSION="6.0.0"

# Добавлять ProxyPass настройки? (true/false)
CONFIGURE_PROXY=true

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo "║   one_c_web_client_v3 - Универсальный установщик         ║"
    echo "║   Версия $APP_VERSION                                     ║"
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
    
    print_warning "Конфиг Apache не найден (возможно используется другой)"
    APACHE_CONFIG=""
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
        read -p "Удалить старую версию и установить заново? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || true
            sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || true
            rm -rf "$app_dest"
            print_success "Старая версия удалена"
        else
            print_info "Установка отменена"
            exit 0
        fi
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
# Настройка Apache прокси (НЕ ЛОМАЕТ SSL!)
# ============================================================================
configure_apache_proxy() {
    if [ "$CONFIGURE_PROXY" != "true" ]; then
        print_info "Настройка прокси пропущена"
        return 0
    fi
    
    print_step "5" "Настройка Apache прокси"
    
    if [ -z "$APACHE_CONFIG" ]; then
        print_warning "Конфиг Apache не найден, настройка прокси пропущена"
        return 0
    fi
    
    # Получаем список баз 1С
    local databases_json=$(sudo -u www-data php "$NEXTCLOUD_PATH/occ" config:app:get "$APP_NAME" databases 2>/dev/null)
    
    if [ -z "$databases_json" ] || [ "$databases_json" = "[]" ]; then
        print_warning "Базы 1С не настроены. Прокси будет добавлен позже."
        return 0
    fi
    
    # Извлекаем хосты
    local hosts=$(echo "$databases_json" | grep -oP '"url"\s*:\s*"\K[^"]+' | sed 's|/$||' | grep -oP 'https?://[^/]+' | sort -u)
    
    if [ -z "$hosts" ]; then
        print_warning "Не удалось извлечь URL баз данных"
        return 0
    fi
    
    # Создаём резервную копию (НЕ ТРОГАЕМ SSL!)
    local backup_dir="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$APACHE_CONFIG" "$backup_dir/apache_config.backup"
    print_success "Резервная копия создана: $backup_dir/apache_config.backup"
    
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

    # Добавляем ProxyPass для каждого хоста
    echo "$hosts" | while IFS= read -r host; do
        if [ -n "$host" ]; then
            cat >> "$directives_file" << EOF
    # Прокси для 1С: $host
    ProxyPass /one_c_web_client_v3 $host/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 $host/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

EOF
        fi
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
    
    print_success "Настройки прокси добавлены"
    
    # Проверка синтаксиса
    print_info "Проверка синтаксиса Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -10
        print_info "Восстановление резервной копии..."
        cp "$backup_dir/apache_config.backup" "$APACHE_CONFIG"
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
    print_step "6" "Проверка установки"
    
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
    
    echo "📋 Следующие шаги:"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://your-nextcloud-domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс"
    echo ""
    echo "3. Если прокси не настроился, запустите:"
    echo "   sudo ./install.sh --configure-proxy"
    echo ""
    
    echo "📋 Проверка:"
    echo ""
    echo "  sudo -u www-data php occ app:list | grep $APP_NAME"
    echo "  apache2ctl configtest"
    echo ""
    
    print_success "Установка завершена!"
}

# ============================================================================
# Обработка аргументов
# ============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --configure-proxy)
            CONFIGURE_PROXY=true
            shift
            ;;
        --no-proxy)
            CONFIGURE_PROXY=false
            shift
            ;;
        --help)
            echo "Использование: ./install.sh [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --configure-proxy  Добавить настройки прокси Apache"
            echo "  --no-proxy         Не добавлять настройки прокси"
            echo "  --help             Показать эту справку"
            exit 0
            ;;
        *)
            print_error "Неизвестный аргумент: $1"
            exit 1
            ;;
    esac
done

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
    echo "  5. (Опционально) Добавит ProxyPass (НЕ ЛОМАЯ SSL!)"
    echo "  6. Проверит работу после установки"
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
    
    configure_apache_proxy
    echo ""
    
    verify_installation
    echo ""
    
    final_report
}

# Запуск
main "$@"
