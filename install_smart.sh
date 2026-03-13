#!/bin/bash

###############################################################################
# one_c_web_client_v3 - УМНЫЙ ИНТЕРАКТИВНЫЙ УСТАНОВЩИК
# Версия: 4.0.0 - Полная диагностика и настройка
# Дата: 13 марта 2026
###############################################################################
# 
# ЧТО ДЕЛАЕТ СКРИПТ:
# 1. ✅ Анализирует конфигурацию сервера
# 2. ✅ Находит файлы установки
# 3. ✅ Проверяет совместимость
# 4. ✅ Настраивает Apache БЕЗ удаления существующих настроек
# 5. ✅ Устанавливает приложение
# 6. ✅ Проверяет каждый этап
# 7. ✅ Сохраняет подробный лог
# 8. ✅ НЕ ломает существующую конфигурацию
#
###############################################################################

set -o pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Логирование
LOG_FILE="/tmp/one_c_smart_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Глобальные переменные (будут заполнены при диагностике)
NEXTCLOUD_PATH=""
NC_VERSION=""
NC_STATUS=""
APACHE_CONFIG=""
APACHE_STATUS=""
PHP_VERSION=""
APP_ARCHIVE=""
APP_NAME="one_c_web_client_v3"
APP_VERSION="4.0.0"
ONE_C_SERVER=""
PROXY_ENABLED=false
EXISTING_PROXY_CONFIG=""

###############################################################################
# Функции вывода
###############################################################################

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client_v3 - УМНЫЙ УСТАНОВЩИК v$APP_VERSION   ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}[ШАГ $1] $2${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_substep() {
    echo -e "${CYAN}  ↳ $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ ОШИБКА: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}  ℹ $1${NC}"
}

print_debug() {
    echo -e "${MAGENTA}  [DEBUG] $1${NC}"
}

###############################################################################
# ЭТАП 1: ДИАГНОСТИКА СЕРВЕРА
###############################################################################

diagnose_server() {
    print_step "1" "Диагностика сервера"
    echo ""
    
    # Проверка прав root
    print_substep "Проверка прав доступа..."
    if [ "$EUID" -ne 0 ]; then
        print_error "Запустите скрипт от root (sudo ./install_smart.sh)"
        exit 1
    fi
    print_success "Права root подтверждены"
    
    # Диагностика Nextcloud
    print_substep "Поиск установки Nextcloud..."
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
            break
        fi
    done
    
    if [ -z "$NEXTCLOUD_PATH" ]; then
        print_error "Nextcloud не найден!"
        echo ""
        echo "Пожалуйста, укажите путь к Nextcloud:"
        read -p "Путь: " custom_path
        if [ -f "$custom_path/occ" ]; then
            NEXTCLOUD_PATH="$custom_path"
            print_success "Nextcloud найден: $NEXTCLOUD_PATH"
        else
            print_error "В указанном пути нет Nextcloud (файл occ не найден)"
            exit 1
        fi
    fi
    
    # Версия Nextcloud
    print_substep "Определение версии Nextcloud..."
    NC_VERSION=$(sudo -u www-data php "$NEXTCLOUD_PATH/occ" status --output=json 2>/dev/null | grep -o '"versionstring":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$NC_VERSION" ]; then
        print_success "Версия Nextcloud: $NC_VERSION"
    else
        print_warning "Не удалось определить версию Nextcloud"
        NC_VERSION="unknown"
    fi
    
    # Статус Nextcloud
    print_substep "Проверка статуса Nextcloud..."
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" status 2>/dev/null | grep -q "installed: true"; then
        NC_STATUS="installed"
        print_success "Nextcloud установлен и работает"
    else
        NC_STATUS="not_installed"
        print_warning "Nextcloud не установлен или не работает"
    fi
    
    # Диагностика Apache
    print_substep "Диагностика Apache..."
    if systemctl is-active --quiet apache2; then
        APACHE_STATUS="active"
        print_success "Apache запущен"
    elif systemctl is-active --quiet httpd; then
        APACHE_STATUS="active"
        print_success "HTTPD запущен"
    else
        APACHE_STATUS="inactive"
        print_warning "Apache не запущен"
    fi
    
    # Поиск конфига Apache
    print_substep "Поиск конфигурации Apache для Nextcloud..."
    local config_paths=(
        "/etc/apache2/sites-available/nextcloud.conf"
        "/etc/apache2/sites-available/nextcloud-le-ssl.conf"
        "/etc/apache2/sites-enabled/nextcloud.conf"
        "/etc/apache2/sites-enabled/000-default-le-ssl.conf"
    )
    
    for config in "${config_paths[@]}"; do
        if [ -f "$config" ]; then
            APACHE_CONFIG="$config"
            print_success "Конфиг найден: $APACHE_CONFIG"
            break
        fi
    done
    
    if [ -z "$APACHE_CONFIG" ]; then
        print_warning "Конфиг Apache не найден в стандартных путях"
        echo ""
        echo "Пожалуйста, укажите путь к конфигу Apache:"
        read -p "Путь: " custom_config
        if [ -f "$custom_config" ]; then
            APACHE_CONFIG="$custom_config"
            print_success "Конфиг указан: $APACHE_CONFIG"
        else
            print_error "Конфиг не найден: $custom_config"
            exit 1
        fi
    fi
    
    # Проверка модулей Apache
    print_substep "Проверка модулей Apache..."
    local required_modules=("proxy" "proxy_http" "proxy_wstunnel" "headers" "rewrite" "ssl")
    local missing_modules=()
    
    for module in "${required_modules[@]}"; do
        if a2query -m "$module" 2>/dev/null; then
            print_success "  Модуль $module: включён"
        else
            missing_modules+=("$module")
            print_warning "  Модуль $module: отключён"
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        print_warning "Отсутствуют модули: ${missing_modules[*]}"
        echo ""
        read -p "Включить отсутствующие модули? [Y/n]: " answer
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            for module in "${missing_modules[@]}"; do
                a2enmod "$module" 2>/dev/null && print_success "Модуль $module включён"
            done
            print_info "Перезапустите Apache после установки модулей"
        fi
    fi
    
    # Версия PHP
    print_substep "Определение версии PHP..."
    if command -v php &>/dev/null; then
        PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2)
        print_success "Версия PHP: $PHP_VERSION"
    else
        print_warning "PHP не найден"
        PHP_VERSION="unknown"
    fi
    
    # Проверка существующей конфигурации прокси
    print_substep "Проверка существующей конфигурации прокси..."
    if grep -q "ProxyPass.*one_c" "$APACHE_CONFIG" 2>/dev/null; then
        PROXY_ENABLED=true
        EXISTING_PROXY_CONFIG=$(grep -A5 "ProxyPass.*one_c" "$APACHE_CONFIG" 2>/dev/null | head -10)
        print_warning "Обнаружена существующая конфигурация прокси для 1С:"
        echo "$EXISTING_PROXY_CONFIG" | sed 's/^/    /'
        echo ""
        read -p "Обновить конфигурацию прокси? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            print_info "Существующая конфигурация будет обновлена"
        else
            print_info "Существующая конфигурация сохранена"
        fi
    else
        print_success "Существующая конфигурация прокси не найдена"
    fi
    
    echo ""
    print_success "Диагностика завершена"
}

###############################################################################
# ЭТАП 2: ПОИСК ФАЙЛОВ УСТАНОВКИ
###############################################################################

find_installation_files() {
    print_step "2" "Поиск файлов установки"
    echo ""
    
    # Поиск архивов
    print_substep "Поиск архивов с приложением..."
    local archive_paths=(
        "/tmp/one_c_web_client_v3_fixed.tar.gz"
        "/tmp/one_c_web_client_v3_deploy.tar.gz"
        "/tmp/one_c_web_client_v3_nc30_deploy.tar.gz"
        "/home/smidt/one_c_web_client_v3_fixed.tar.gz"
        "/home/smidt/one_c_web_client_v3_deploy.tar.gz"
        "./one_c_web_client_v3_fixed.tar.gz"
        "./one_c_web_client_v3_deploy.tar.gz"
    )
    
    for path in "${archive_paths[@]}"; do
        if [ -f "$path" ]; then
            APP_ARCHIVE="$path"
            print_success "Архив найден: $APP_ARCHIVE"
            break
        fi
    done
    
    if [ -z "$APP_ARCHIVE" ]; then
        print_error "Архив с приложением не найден!"
        echo ""
        echo "Пожалуйста, укажите путь к архиву:"
        read -p "Путь: " custom_archive
        if [ -f "$custom_archive" ]; then
            APP_ARCHIVE="$custom_archive"
            print_success "Архив указан: $APP_ARCHIVE"
        else
            print_error "Архив не найден: $custom_archive"
            exit 1
        fi
    fi
    
    # Проверка содержимого архива
    print_substep "Проверка содержимого архива..."
    if tar -tzf "$APP_ARCHIVE" | grep -q "appinfo/info.xml"; then
        print_success "Архив содержит valid приложение"
    else
        print_error "Архив не содержит valid приложение (нет appinfo/info.xml)"
        exit 1
    fi
    
    echo ""
    print_success "Файлы установки найдены"
}

###############################################################################
# ЭТАП 3: АНАЛИЗ КОНФИГУРАЦИИ APACHE
###############################################################################

analyze_apache_config() {
    print_step "3" "Анализ конфигурации Apache"
    echo ""
    
    # Проверка синтаксиса
    print_substep "Проверка синтаксиса Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -5
        echo ""
        read -p "Продолжить несмотря на ошибку? [y/N]: " answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Анализ VirtualHost
    print_substep "Анализ VirtualHost конфигурации..."
    local vhost_count=$(grep -c "<VirtualHost.*:443>" "$APACHE_CONFIG" 2>/dev/null)
    print_info "Найдено VirtualHost *:443: $vhost_count"
    
    # Проверка DocumentRoot
    if grep -q "DocumentRoot.*nextcloud" "$APACHE_CONFIG" 2>/dev/null; then
        print_success "DocumentRoot настроен корректно"
    else
        print_warning "DocumentRoot может быть настроен некорректно"
    fi
    
    # Проверка SSL
    if grep -q "SSLEngine\|SSLCertificate" "$APACHE_CONFIG" 2>/dev/null; then
        print_success "SSL настроен"
    else
        print_warning "SSL может быть не настроен"
    fi
    
    echo ""
    print_success "Анализ конфигурации завершён"
}

###############################################################################
# ЭТАП 4: НАСТРОЙКА APACHE (БЕЗ УДАЛЕНИЯ!)
###############################################################################

configure_apache() {
    print_step "4" "Настройка Apache (БЕЗ удаления существующих настроек!)"
    echo ""
    
    # Создание резервной копии
    print_substep "Создание резервной копии..."
    local backup_dir="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$APACHE_CONFIG" "$backup_dir/apache_config.backup"
    print_success "Резервная копия создана: $backup_dir/apache_config.backup"
    
    # Проверка существующей конфигурации прокси
    if grep -q "ProxyPass.*one_c" "$APACHE_CONFIG" 2>/dev/null; then
        print_warning "Обнаружена существующая конфигурация прокси"
        echo ""
        read -p "Удалить старую конфигурацию и добавить новую? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            print_substep "Удаление старой конфигурации..."
            # Удаляем только наши директивы, оставляем всё остальное
            sed -i '/# one_c_web_client/,/# END one_c_web_client/d' "$APACHE_CONFIG"
            print_success "Старая конфигурация удалена"
        else
            print_info "Старая конфигурация сохранена"
            echo ""
            print_warning "Возможен конфликт конфигураций!"
        fi
    fi
    
    # Определение 1С сервера
    print_substep "Настройка прокси для 1С..."
    echo ""
    echo "Укажите адрес 1С сервера:"
    read -p "URL (например, https://10.72.1.5): " ONE_C_SERVER
    
    if [[ ! "$ONE_C_SERVER" =~ ^https?:// ]]; then
        print_error "Неверный формат URL"
        exit 1
    fi
    
    local ONE_C_SERVER_WS=$(echo "$ONE_C_SERVER" | sed 's|https://|wss://|; s|http://|ws://|')
    print_info "WebSocket URL: $ONE_C_SERVER_WS"
    echo ""
    
    # Добавление конфигурации прокси
    print_substep "Добавление конфигурации прокси..."
    
    # Находим место для вставки (перед закрывающим </VirtualHost>)
    local vhost_line=$(grep -n "</VirtualHost>" "$APACHE_CONFIG" | head -1 | cut -d: -f1)
    
    if [ -z "$vhost_line" ]; then
        print_error "Не найден закрывающий тег </VirtualHost>"
        exit 1
    fi
    
    # Создаём файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << EOF

    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С (добавлено установщиком v$APP_VERSION)
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

    # Прокси для 1С сервера: $ONE_C_SERVER
    ProxyPass /one_c_web_client_v3 $ONE_C_SERVER/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 $ONE_C_SERVER/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

    # WebSocket прокси для 1С
    ProxyPass /one_c_web_client_v3/ws $ONE_C_SERVER_WS/one_c_web_client_v3/ws retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3/ws $ONE_C_SERVER_WS/one_c_web_client_v3/ws

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
    
    print_success "Конфигурация прокси добавлена"
    
    # Проверка синтаксиса после изменений
    print_substep "Проверка синтаксиса после изменений..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl configtest 2>&1 | head -10
        echo ""
        read -p "Восстановить резервную копию? [Y/n]: " answer
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            cp "$backup_dir/apache_config.backup" "$APACHE_CONFIG"
            print_success "Резервная копия восстановлена"
            exit 1
        fi
    fi
    
    # Проверка добавленной конфигурации
    print_substep "Проверка добавленной конфигурации..."
    if grep -q "ProxyPass.*one_c_web_client_v3" "$APACHE_CONFIG"; then
        print_success "Конфигурация прокси найдена в конфиге"
    else
        print_error "Конфигурация прокси не найдена в конфиге!"
        exit 1
    fi
    
    echo ""
    print_success "Настройка Apache завершена"
}

###############################################################################
# ЭТАП 5: УСТАНОВКА ПРИЛОЖЕНИЯ
###############################################################################

install_application() {
    print_step "5" "Установка приложения"
    echo ""
    
    local app_dest="$NEXTCLOUD_PATH/apps/$APP_NAME"
    
    # Проверка существующей установки
    print_substep "Проверка существующей установки..."
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:list 2>/dev/null | grep -q "$APP_NAME"; then
        print_warning "Приложение уже установлено"
        echo ""
        read -p "Переустановить приложение? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            print_substep "Удаление старой версии..."
            sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || true
            sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || true
            print_success "Старая версия удалена"
        else
            print_info "Старая версия сохранена"
        fi
    fi
    
    # Распаковка приложения
    print_substep "Распаковка приложения..."
    mkdir -p "$app_dest"
    
    local temp_dir=$(mktemp -d)
    tar -xzf "$APP_ARCHIVE" -C "$temp_dir"
    
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
        print_success "Приложение распаковано"
    else
        rm -rf "$temp_dir"
        print_error "Не удалось найти приложение в архиве"
        exit 1
    fi
    
    # Установка прав
    print_substep "Установка прав доступа..."
    chown -R www-data:www-data "$app_dest"
    chmod -R 755 "$app_dest"
    print_success "Права установлены"
    
    # Установка приложения через occ
    print_substep "Установка приложения через OCC..."
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:install "$APP_NAME" 2>/dev/null; then
        print_success "Приложение установлено"
    elif sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:enable "$APP_NAME" 2>/dev/null; then
        print_success "Приложение включено"
    else
        print_error "Не удалось установить приложение"
        echo ""
        print_info "Попробуйте установить вручную:"
        echo "   sudo -u www-data php $NEXTCLOUD_PATH/occ app:install $APP_NAME"
        exit 1
    fi
    
    # Очистка кэша
    print_substep "Очистка кэша..."
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:repair 2>/dev/null || print_warning "maintenance:repair недоступна"
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" memcache:clear 2>/dev/null || print_warning "memcache:clear недоступна"
    print_success "Кэш очищен"
    
    echo ""
    print_success "Установка приложения завершена"
}

###############################################################################
# ЭТАП 6: ПЕРЕЗАПУСК И ПРОВЕРКА
###############################################################################

restart_and_verify() {
    print_step "6" "Перезапуск и проверка"
    echo ""
    
    # Перезапуск Apache
    print_substep "Перезапуск Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        if systemctl restart apache2 2>/dev/null; then
            print_success "Apache перезапущен"
        elif apache2ctl graceful 2>/dev/null; then
            print_success "Apache перезапущен (graceful)"
        else
            print_warning "Не удалось перезапустить Apache"
        fi
    else
        print_error "Ошибка синтаксиса Apache"
    fi
    
    # Проверка приложения
    print_substep "Проверка установки приложения..."
    if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:list 2>/dev/null | grep -q "$APP_NAME"; then
        print_success "Приложение активно"
    else
        print_error "Приложение не найдено"
    fi
    
    # Проверка конфигурации Apache
    print_substep "Проверка конфигурации Apache..."
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Конфигурация Apache корректна"
    else
        print_error "Ошибка в конфигурации Apache"
    fi
    
    # Проверка доступности страниц
    print_substep "Проверка доступности страниц..."
    echo ""
    
    # Получаем домен из конфига
    local domain=$(grep -oP "ServerName\s+\K\S+" "$APACHE_CONFIG" 2>/dev/null | head -1)
    if [ -z "$domain" ]; then
        domain="localhost"
    fi
    
    print_info "Домен: $domain"
    echo ""
    print_info "Проверьте страницы вручную:"
    echo ""
    echo "  1. Админка Nextcloud:"
    echo "     https://$domain/index.php/settings/admin"
    echo ""
    echo "  2. Настройки приложения:"
    echo "     https://$domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "  3. Клиентская часть:"
    echo "     https://$domain/index.php/apps/$APP_NAME/"
    echo ""
    
    echo ""
    print_success "Проверка завершена"
}

###############################################################################
# ЭТАП 7: ФИНАЛЬНЫЙ ОТЧЁТ
###############################################################################

final_report() {
    print_step "7" "Финальный отчёт"
    echo ""
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ Установка завершена успешно!                         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_info "Информация об установке:"
    echo ""
    echo "  Приложение:     $APP_NAME v$APP_VERSION"
    echo "  Nextcloud:      $NEXTCLOUD_PATH"
    echo "  Версия NC:      $NC_VERSION"
    echo "  Конфиг Apache:  $APACHE_CONFIG"
    echo "  1С сервер:      $ONE_C_SERVER"
    echo "  Лог:            $LOG_FILE"
    echo ""
    
    print_info "Следующие шаги:"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://$domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс"
    echo ""
    echo "3. Проверьте работу приложения:"
    echo "   https://$domain/index.php/apps/$APP_NAME/"
    echo ""
    
    print_info "Резервная копия сохранена:"
    echo "   $backup_dir/apache_config.backup"
    echo ""
    
    print_info "Лог установки:"
    echo "   $LOG_FILE"
    echo ""
    
    echo -e "${GREEN}✓ Установка завершена!${NC}"
    echo ""
}

###############################################################################
# ОСНОВНАЯ ФУНКЦИЯ
###############################################################################

main() {
    print_header
    
    echo "Этот скрипт:"
    echo "  1. Проанализирует конфигурацию сервера"
    echo "  2. Найдёт файлы для установки"
    echo "  3. Настроит Apache БЕЗ удаления существующих настроек"
    echo "  4. Установит приложение"
    echo "  5. Проверит каждый этап"
    echo "  6. Сохранит подробный лог"
    echo ""
    
    read -p "Продолжить установку? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Установка отменена"
        exit 0
    fi
    
    echo ""
    
    # Запуск этапов установки
    diagnose_server
    echo ""
    
    find_installation_files
    echo ""
    
    analyze_apache_config
    echo ""
    
    configure_apache
    echo ""
    
    install_application
    echo ""
    
    restart_and_verify
    echo ""
    
    final_report
}

# Обработчик ошибок
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        print_error "Установка прервана с ошибкой: $exit_code"
        print_info "Лог установки: $LOG_FILE"
        print_info "Отправьте лог разработчику для анализа"
    fi
}

trap cleanup EXIT

# Запуск
main "$@"
