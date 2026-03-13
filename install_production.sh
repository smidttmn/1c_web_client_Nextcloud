#!/bin/bash

###############################################################################
# one_c_web_client_v3 - Установщик для продакшн-сервера
# drive.technoorganic.info / drive.nppsgt.com
# Версия: 3.2.0 - Исправленная конфигурация Apache
# Дата: 13 марта 2026
###############################################################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Логирование
LOG_FILE="/tmp/one_c_production_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

###############################################################################
# Функции вывода
###############################################################################
print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client_v3 - Установка на продакшн             ║"
    echo "║   drive.technoorganic.info / drive.nppsgt.com             ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${YELLOW}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

###############################################################################
# Проверка прав root
###############################################################################
if [ "$EUID" -ne 0 ]; then
    print_error "Ошибка: Запустите скрипт от root (sudo ./install_production.sh)"
    exit 1
fi

###############################################################################
# Конфигурация
###############################################################################
NEXTCLOUD_PATH="/var/www/html/nextcloud"
APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
APP_NAME="one_c_web_client_v3"
APP_VERSION="3.2.0"
ONE_C_SERVER="https://10.72.1.5"
ONE_C_SERVER_WS="wss://10.72.1.5"

###############################################################################
# Функции
###############################################################################

# Проверка модулей Apache
check_apache_modules() {
    local required_modules=("proxy" "proxy_http" "proxy_wstunnel" "headers" "rewrite" "ssl" "substitute")
    local missing=()

    for module in "${required_modules[@]}"; do
        if ! a2query -m "$module" 2>/dev/null; then
            missing+=("$module")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "${missing[@]}"
        return 1
    fi

    return 0
}

# Резервное копирование
backup_config() {
    local backup_dir="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    if [ -f "$APACHE_CONFIG" ]; then
        cp "$APACHE_CONFIG" "$backup_dir/apache_config.backup"
        print_success "Резервная копия конфига: $backup_dir/apache_config.backup"
    fi

    # Резервная копия приложения
    local app_dir="$NEXTCLOUD_PATH/apps/$APP_NAME"
    if [ -d "$app_dir" ]; then
        cp -r "$app_dir" "$backup_dir/app_backup" 2>/dev/null || true
    fi

    echo "$backup_dir"
}

# Восстановление из резервной копии
restore_backup() {
    local backup_dir="$1"

    print_warning "Восстановление резервной копии..."

    if [ -f "$backup_dir/apache_config.backup" ]; then
        cp "$backup_dir/apache_config.backup" "$APACHE_CONFIG"
        print_success "Конфиг восстановлен"
    fi

    apache2ctl graceful 2>/dev/null || systemctl reload apache2 2>/dev/null || true
    print_error "Конфигурация откачена"
}

# Установка приложения
install_app_files() {
    local app_dest="$NEXTCLOUD_PATH/apps/$APP_NAME"

    print_step "1" "Копирование файлов приложения..."

    # Ищем архив
    local app_archive=""
    local search_paths=(
        "./one_c_web_client_v3_deploy.tar.gz"
        "./one_c_web_client_v3_full.tar.gz"
        "./one_c_v3_all.tar.gz"
        "/tmp/one_c_web_client_v3_deploy.tar.gz"
        "/home/smidt/one_c_web_client_deploy.tar.gz"
    )

    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then
            app_archive="$path"
            break
        fi
    done

    if [ -z "$app_archive" ]; then
        print_error "Архив с приложением не найден!"
        print_info "Положите один из файлов рядом со скриптом:"
        echo "   - one_c_web_client_v3_deploy.tar.gz"
        echo "   - one_c_web_client_v3_full.tar.gz"
        return 1
    fi

    print_info "Распаковка из: $app_archive"

    # Создаем директорию
    mkdir -p "$app_dest"

    # Распаковываем
    local temp_dir=$(mktemp -d)
    tar -xzf "$app_archive" -C "$temp_dir"

    # Ищем директорию с приложением
    local found_dir=""
    for d in "$temp_dir"/*; do
        if [ -d "$d" ] && [ -f "$d/appinfo/info.xml" ]; then
            found_dir="$d"
            break
        fi
    done

    if [ -n "$found_dir" ]; then
        cp -r "$found_dir"/* "$app_dest/"
        rm -rf "$temp_dir"
        print_success "Файлы приложения скопированы"
    else
        rm -rf "$temp_dir"
        print_error "Не удалось найти приложение в архиве"
        return 1
    fi

    # Права
    chown -R www-data:www-data "$app_dest"
    chmod -R 755 "$app_dest"
    print_success "Права установлены"
}

# Настройка Apache - ИСПРАВЛЕННАЯ ВЕРСИЯ
configure_apache() {
    print_step "2" "Настройка Apache..."

    # Резервная копия
    local backup_dir=$(backup_config)
    print_info "Резервная копия: $backup_dir"

    # Включаем модули
    print_info "Включение модулей Apache..."
    a2enmod proxy proxy_http proxy_wstunnel headers rewrite ssl substitute 2>/dev/null || true

    # Проверка модулей
    local missing_modules=$(check_apache_modules)
    if [ $? -eq 1 ]; then
        print_warning "Не удалось включить модули: $missing_modules"
    else
        print_success "Все модули Apache включены"
    fi

    # Проверяем, есть ли уже наши настройки
    if grep -q "ProxyPass.*one_c_web_client" "$APACHE_CONFIG" 2>/dev/null; then
        print_warning "Настройки one_c_web_client уже найдены в конфиге"
        read -p "Удалить старые настройки и добавить новые? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Удаляем старые настройки
            print_info "Удаление старых настроек..."
            sed -i '/# one_c_web_client_v3 - Прокси для 1С/,/# Конец настроек one_c_web_client_v3/d' "$APACHE_CONFIG"
            print_success "Старые настройки удалены"
        else
            print_info "Установка отменена"
            return 1
        fi
    fi

    # Создаем файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << 'EOF'

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С
    # ===================================================================

    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # Исключения для статических файлов Nextcloud (ОБЯЗАТЕЛЬНО ДО ProxyPass!)
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

    # Прокси для 1С сервера: https://10.72.1.5
    ProxyPass /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

    # WebSocket прокси для 1С
    ProxyPass /one_c_web_client_v3/ws wss://10.72.1.5/one_c_web_client_v3/ws retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3/ws wss://10.72.1.5/one_c_web_client_v3/ws

    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # Конец настроек one_c_web_client_v3
    # ===================================================================

EOF

    # Находим строку с </VirtualHost> для *:443
    local vhost_line=$(grep -n "</VirtualHost>" "$APACHE_CONFIG" | head -1 | cut -d: -f1)

    if [ -z "$vhost_line" ]; then
        print_error "Не найден закрывающий тег </VirtualHost> в конфиге"
        rm "$directives_file"
        return 1
    fi

    print_success "Найден </VirtualHost> в строке $vhost_line"

    # Вставляем директивы перед </VirtualHost>
    local line_before=$((vhost_line - 1))
    sed -i "${line_before}r $directives_file" "$APACHE_CONFIG"

    rm "$directives_file"

    # Проверяем синтаксис
    print_info "Проверка синтаксиса Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -10

        # Восстанавливаем резервную копию
        restore_backup "$backup_dir"
        return 1
    fi
}

# Установка приложения в Nextcloud
install_nextcloud_app() {
    print_step "3" "Установка приложения в Nextcloud..."

    # Отключаем старые версии
    print_info "Отключение старых версий..."
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable one_c_web_client 2>/dev/null || true
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable one_c_web_client_v2 2>/dev/null || true

    # Удаляем старые версии
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:remove one_c_web_client 2>/dev/null || true
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:remove one_c_web_client_v2 2>/dev/null || true

    # Устанавливаем новую
    print_info "Установка $APP_NAME..."
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:install "$APP_NAME" 2>/dev/null; then
        print_success "Приложение установлено"
    elif sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:enable "$APP_NAME" 2>/dev/null; then
        print_success "Приложение включено"
    else
        print_error "Не удалось установить приложение"
        return 1
    fi

    # Очищаем кэш
    print_info "Очистка кэша..."
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:repair
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" cache:clear 2>/dev/null || true

    print_success "Кэш очищен"
}

# Перезапуск Apache
restart_apache() {
    print_step "4" "Перезапуск Apache..."

    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        if apache2ctl graceful 2>/dev/null; then
            print_success "Apache перезапущен (graceful)"
        elif systemctl reload apache2 2>/dev/null; then
            print_success "Apache перезапущен (systemctl reload)"
        else
            print_error "Не удалось перезапустить Apache"
            return 1
        fi
    else
        print_error "Ошибка синтаксиса Apache"
        apache2ctl configtest
        return 1
    fi
}

# Проверка установки
verify_installation() {
    print_step "5" "Проверка установки..."

    local errors=0

    # Проверка приложения
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:list | grep -q "$APP_NAME"; then
        print_success "Приложение активно"
    else
        print_error "Приложение не найдено"
        ((errors++)) || true
    fi

    # Проверка конфига
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Конфигурация Apache корректна"
    else
        print_error "Ошибка в конфигурации Apache"
        ((errors++)) || true
    fi

    return $errors
}

# Итог
print_summary() {
    echo ""
    print_success "╔═══════════════════════════════════════════════════════════╗"
    print_success "║   Установка завершена успешно!                            ║"
    print_success "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${BLUE}📋 Информация об установке:${NC}"
    echo ""
    echo "  Приложение:     $APP_NAME v$APP_VERSION"
    echo "  Nextcloud:      $NEXTCLOUD_PATH"
    echo "  Конфиг Apache:  $APACHE_CONFIG"
    echo "  1С сервер:      $ONE_C_SERVER"
    echo "  Лог:            $LOG_FILE"
    echo ""

    echo -e "${BLUE}📋 Следующие шаги:${NC}"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://drive.technoorganic.info/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс"
    echo ""
    echo "3. Проверьте работу приложения:"
    echo "   https://drive.technoorganic.info/index.php/apps/$APP_NAME/"
    echo ""

    echo -e "${YELLOW}⚠  Важно:${NC}"
    echo "   - Убедитесь, что 1С сервер (10.72.1.5) доступен с сервера Nextcloud"
    echo "   - Проверьте работу HTTPS на 1С сервере"
    echo "   - Резервная копия сохранена: $backup_dir"
    echo ""

    echo -e "${GREEN}✓ Установка завершена!${NC}"
}

###############################################################################
# Основная функция
###############################################################################

main() {
    print_header

    print_info "Конфигурация установки:"
    echo ""
    echo "  Nextcloud:      $NEXTCLOUD_PATH"
    echo "  Apache конфиг:  $APACHE_CONFIG"
    echo "  Приложение:     $APP_NAME v$APP_VERSION"
    echo "  1С сервер:      $ONE_C_SERVER"
    echo ""

    read -p "Продолжить установку? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Установка отменена"
        exit 0
    fi

    # Проверка существования Nextcloud
    if [ ! -f "$NEXTCLOUD_PATH/occ" ]; then
        print_error "Nextcloud не найден: $NEXTCLOUD_PATH"
        exit 1
    fi

    # Проверка существования Apache конфига
    if [ ! -f "$APACHE_CONFIG" ]; then
        print_error "Конфиг Apache не найден: $APACHE_CONFIG"
        exit 1
    fi

    # Установка
    echo ""
    print_header "Начало установки"
    echo ""

    install_app_files
    configure_apache
    install_nextcloud_app
    restart_apache

    # Проверка
    verify_installation

    # Итог
    print_summary
}

# Обработчик ошибок
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Установка прервана с ошибкой: $exit_code"
        print_info "Лог установки: $LOG_FILE"
    fi
}

trap cleanup EXIT

# Запуск
main "$@"
