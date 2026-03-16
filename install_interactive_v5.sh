#!/bin/bash
# ============================================================================
# one_c_web_client_v3 - ИНТЕРАКТИВНЫЙ УСТАНОВЩИК С ПРОВЕРКАМИ
# Версия: 5.0.0 - Полная диагностика и настройка Apache
# ============================================================================
# 
# ЧТО ДЕЛАЕТ СКРИПТ:
# 1. ✅ Проверяет права и зависимости
# 2. ✅ Находит Nextcloud и Apache конфиг
# 3. ✅ Проверяет модули Apache
# 4. ✅ Получает список баз 1С из Nextcloud
# 5. ✅ Добавляет ProxyPass для каждой базы (НЕ ЗАМЕНЯЯ существующие настройки!)
# 6. ✅ Проверяет синтаксис Apache после изменений
# 7. ✅ Перезапускает Apache
# 8. ✅ Проверяет работу после установки
# 9. ✅ Создаёт резервную копию
# 10. ✅ Сохраняет подробный лог
# ============================================================================

set -o pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Логирование
LOG_FILE="/tmp/one_c_interactive_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Глобальные переменные
NEXTCLOUD_PATH=""
APACHE_CONFIG=""
APP_NAME="one_c_web_client_v3"
BACKUP_DIR=""

###############################################################################
# Функции вывода
###############################################################################
print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client_v3 - Интерактивный установщик         ║"
    echo "║   Версия 5.0.0 - Полная диагностика и настройка          ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}[ШАГ $1] $2${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
print_error() { echo -e "${RED}  ✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${CYAN}  ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}  ⚠ $1${NC}"; }

###############################################################################
# Откат изменений
###############################################################################
rollback() {
    print_error "Произошла ошибка! Выполняю откат..."
    
    if [ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/apache_config.backup" ]; then
        cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
        print_success "Конфиг Apache восстановлен"
        systemctl restart apache2
        print_success "Apache перезапущен"
    fi
    
    print_info "Лог установки: $LOG_FILE"
    print_info "Отправьте этот лог разработчику для анализа"
    exit 1
}

trap rollback ERR

###############################################################################
# ШАГ 1: Проверка прав
###############################################################################
check_root() {
    print_step "1" "Проверка прав доступа"
    
    if [ "$EUID" -ne 0 ]; then
        print_error "Запустите скрипт от root (sudo ./install_interactive.sh)"
        exit 1
    fi
    print_success "Права root подтверждены"
}

###############################################################################
# ШАГ 2: Поиск Nextcloud
###############################################################################
find_nextcloud() {
    print_step "2" "Поиск установки Nextcloud"
    
    local nc_paths=(
        "/var/www/html/nextcloud"
        "/var/www/nextcloud"
        "/srv/www/nextcloud"
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

###############################################################################
# ШАГ 3: Поиск конфига Apache
###############################################################################
find_apache_config() {
    print_step "3" "Поиск конфигурации Apache"
    
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
    echo "Пожалуйста, укажите путь к конфигу Apache:"
    read -p "Путь: " custom_config
    if [ -f "$custom_config" ]; then
        APACHE_CONFIG="$custom_config"
        print_success "Конфиг Apache указан: $APACHE_CONFIG"
    else
        print_error "Конфиг не найден: $custom_config"
        exit 1
    fi
}

###############################################################################
# ШАГ 4: Проверка модулей Apache
###############################################################################
check_apache_modules() {
    print_step "4" "Проверка модулей Apache"
    
    local required_modules=("proxy" "proxy_http" "proxy_wstunnel" "headers" "rewrite" "ssl")
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
        print_info "Перезапустите Apache после установки модулей"
    fi
}

###############################################################################
# ШАГ 5: Получение списка баз 1С
###############################################################################
get_1c_databases() {
    print_step "5" "Получение списка баз 1С из Nextcloud"
    
    local databases_json=$(sudo -u www-data php "$NEXTCLOUD_PATH/occ" config:app:get one_c_web_client_v3 databases 2>/dev/null)
    
    if [ -z "$databases_json" ] || [ "$databases_json" = "[]" ]; then
        print_warning "Базы 1С не настроены в Nextcloud"
        print_info "Настройте базы через админ-панель Nextcloud:"
        echo "   https://your-nextcloud-domain/index.php/settings/admin/one_c_web_client_v3"
        echo ""
        read -p "Продолжить без настройки прокси? [y/N]: " answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            exit 0
        fi
        return 1
    fi
    
    print_success "Базы 1С найдены"
    
    # Извлекаем уникальные хосты
    HOSTS=$(echo "$databases_json" | grep -oP '"url"\s*:\s*"\K[^"]+' | sed 's|/$||' | grep -oP 'https?://[^/]+' | sort -u)
    
    if [ -z "$HOSTS" ]; then
        print_error "Не удалось извлечь URL баз данных"
        return 1
    fi
    
    print_info "Найдены хосты 1С:"
    echo "$HOSTS" | while read -r host; do
        echo "   - $host"
    done
    
    return 0
}

###############################################################################
# ШАГ 6: Резервная копия
###############################################################################
create_backup() {
    print_step "6" "Создание резервной копии"
    
    BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
    print_success "Резервная копия создана: $BACKUP_DIR/apache_config.backup"
}

###############################################################################
# ШАГ 7: Настройка Apache прокси
###############################################################################
configure_apache_proxy() {
    print_step "7" "Настройка Apache прокси"
    
    # Проверяем, есть ли уже наши настройки
    if grep -q "one_c_web_client_v3 - Прокси" "$APACHE_CONFIG" 2>/dev/null; then
        print_warning "Настройки one_c_web_client_v3 уже найдены в конфиге"
        read -p "Удалить старые настройки и добавить новые? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            print_info "Удаление старых настроек..."
            sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$APACHE_CONFIG"
            print_success "Старые настройки удалены"
        else
            print_info "Старые настройки сохранены"
            return 0
        fi
    fi
    
    # Находим строку с </VirtualHost>
    local vhost_line=$(grep -n "</VirtualHost>" "$APACHE_CONFIG" | head -1 | cut -d: -f1)
    
    if [ -z "$vhost_line" ]; then
        print_error "Не найден закрывающий тег </VirtualHost>"
        exit 1
    fi
    
    print_info "Добавление настроек прокси перед строкой $vhost_line..."
    
    # Создаём файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено установщиком)
    # ===================================================================

    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # Исключения для статических файлов Nextcloud (НЕ проксировать!)
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
    echo "$HOSTS" | while IFS= read -r host; do
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
}

###############################################################################
# ШАГ 8: Проверка синтаксиса
###############################################################################
check_apache_syntax() {
    print_step "8" "Проверка синтаксиса Apache"
    
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -10
        print_info "Восстановление резервной копии..."
        cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
        exit 1
    fi
}

###############################################################################
# ШАГ 9: Перезапуск Apache
###############################################################################
restart_apache() {
    print_step "9" "Перезапуск Apache"
    
    if systemctl restart apache2; then
        print_success "Apache перезапущен"
    else
        print_error "Не удалось перезапустить Apache"
        exit 1
    fi
}

###############################################################################
# ШАГ 10: Проверка после установки
###############################################################################
verify_installation() {
    print_step "10" "Проверка после установки"
    
    # Проверка приложения
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:list 2>/dev/null | grep -q "$APP_NAME"; then
        print_success "Приложение $APP_NAME активно"
    else
        print_warning "Приложение $APP_NAME не найдено"
    fi
    
    # Проверка конфига
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Конфигурация Apache корректна"
    else
        print_error "Ошибка в конфигурации Apache"
    fi
    
    # Проверка прокси
    if grep -q "ProxyPass.*one_c_web_client_v3" "$APACHE_CONFIG"; then
        print_success "ProxyPass настроен"
    else
        print_warning "ProxyPass не найден"
    fi
}

###############################################################################
# ФИНАЛЬНЫЙ ОТЧЁТ
###############################################################################
final_report() {
    print_header "Установка завершена!"
    
    echo ""
    echo "📋 Информация об установке:"
    echo ""
    echo "  Nextcloud:      $NEXTCLOUD_PATH"
    echo "  Конфиг Apache:  $APACHE_CONFIG"
    echo "  Резервная копия: $BACKUP_DIR/apache_config.backup"
    echo "  Лог:            $LOG_FILE"
    echo ""
    
    echo "📋 Следующие шаги:"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://your-nextcloud-domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс"
    echo ""
    echo "3. Запустите этот скрипт снова для настройки прокси"
    echo ""
    
    echo "📋 Проверка:"
    echo ""
    echo "  sudo -u www-data php occ app:list | grep $APP_NAME"
    echo "  apache2ctl configtest"
    echo ""
    
    print_success "Установка завершена!"
}

###############################################################################
# ОСНОВНАЯ ФУНКЦИЯ
###############################################################################
main() {
    print_header
    
    echo "Этот скрипт:"
    echo "  1. Проверит права и зависимости"
    echo "  2. Найдёт Nextcloud и Apache конфиг"
    echo "  3. Проверит модули Apache"
    echo "  4. Получит список баз 1С"
    echo "  5. Добавит ProxyPass (НЕ ЗАМЕНЯЯ существующие настройки!)"
    echo "  6. Проверит синтаксис Apache"
    echo "  7. Перезапустит Apache"
    echo "  8. Проверит работу после установки"
    echo ""
    
    read -p "Продолжить установку? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Установка отменена"
        exit 0
    fi
    
    echo ""
    
    # Запуск этапов установки
    check_root
    echo ""
    
    find_nextcloud
    echo ""
    
    find_apache_config
    echo ""
    
    check_apache_modules
    echo ""
    
    if get_1c_databases; then
        create_backup
        echo ""
        
        configure_apache_proxy
        echo ""
        
        check_apache_syntax
        echo ""
        
        restart_apache
        echo ""
        
        verify_installation
        echo ""
        
        final_report
    else
        print_warning "Настройка прокси пропущена"
        final_report
    fi
}

# Обработчик ошибок
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        print_error "Установка прервана с ошибкой: $exit_code"
        print_info "Лог установки: $LOG_FILE"
    fi
}

trap cleanup EXIT

# Запуск
main "$@"
