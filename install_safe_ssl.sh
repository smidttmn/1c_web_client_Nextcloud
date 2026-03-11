#!/bin/bash

###############################################################################
# one_c_web_client_v3 - Безопасный установщик с SSL
# Версия: 3.1.1 - Улучшенная безопасность и надёжность
# Дата: Март 2026
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
LOG_FILE="/tmp/one_c_install_safe_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

###############################################################################
# Функции вывода
###############################################################################
print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client_v3 - Безопасный установщик с SSL       ║"
    echo "║   Версия 3.1.1 - Улучшенная безопасность                  ║"
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
    print_error "Ошибка: Запустите скрипт от root (sudo ./install_safe_ssl.sh)"
    exit 1
fi

###############################################################################
# Функции определения конфигурации
###############################################################################

# Найти установку Nextcloud
find_nextcloud_path() {
    local paths=(
        "/var/www/nextcloud"
        "/var/www/html/nextcloud"
        "/var/www/nextcloud-aio/nextcloud"
        "/snap/nextcloud/current/nextcloud"
        "/usr/share/nextcloud"
    )
    
    for path in "${paths[@]}"; do
        if [ -f "$path/occ" ] && [ -d "$path/apps" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Найти конфиг Apache с SSL
find_apache_ssl_configs() {
    local configs=()
    local search_paths=(
        "/etc/apache2/sites-available/nextcloud-le-ssl.conf"
        "/etc/apache2/sites-available/nextcloud.conf"
        "/etc/apache2/sites-available/nextcloud-ssl.conf"
        "/etc/apache2/sites-enabled/nextcloud.conf"
        "/etc/apache2/sites-enabled/000-default-le-ssl.conf"
    )
    
    for config in "${search_paths[@]}"; do
        if [ -f "$config" ] && grep -q "SSLEngine\|SSLProxyEngine" "$config" 2>/dev/null; then
            configs+=("$config")
        fi
    done
    
    # Если не найдено, ищем все конфиги с VirtualHost *:443
    if [ ${#configs[@]} -eq 0 ]; then
        while IFS= read -r config; do
            if grep -q "VirtualHost.*:443" "$config" 2>/dev/null; then
                configs+=("$config")
            fi
        done < <(find /etc/apache2 -name "*.conf" -type f 2>/dev/null)
    fi
    
    printf '%s\n' "${configs[@]}"
}

# Проверить домен в конфиге
check_domain_in_config() {
    local config="$1"
    local domain="$2"
    
    if grep -q "ServerName.*$domain\|ServerAlias.*$domain" "$config" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Получить домены из конфига
get_domains_from_config() {
    local config="$1"
    local domains=""
    
    domains=$(grep -oP "(ServerName|ServerAlias)\s+\K\S+" "$config" 2>/dev/null | tr '\n' ' ')
    echo "$domains"
}

# Проверить модули Apache
check_apache_modules() {
    local required_modules=("proxy" "proxy_http" "proxy_wstunnel" "headers" "rewrite" "ssl")
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

###############################################################################
# Функции резервного копирования
###############################################################################

backup_config() {
    local config="$1"
    local backup_dir="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    # Копируем конфиг
    if [ -f "$config" ]; then
        cp "$config" "$backup_dir/apache_config.backup"
        print_success "Резервная копия конфига: $backup_dir/apache_config.backup"
    fi
    
    # Копируем симлинк из sites-enabled если есть
    local enabled_link="/etc/apache2/sites-enabled/$(basename "$config")"
    if [ -L "$enabled_link" ]; then
        cp -P "$enabled_link" "$backup_dir/apache_symlink.backup" 2>/dev/null || true
    fi
    
    # Копируем приложение если есть
    local app_dir="$NEXTCLOUD_PATH/apps/$APP_NAME"
    if [ -d "$app_dir" ]; then
        cp -r "$app_dir" "$backup_dir/app_backup" 2>/dev/null || true
    fi
    
    echo "$backup_dir"
}

restore_backup() {
    local backup_dir="$1"
    local config="$2"
    
    print_warning "Восстановление резервной копии..."
    
    if [ -f "$backup_dir/apache_config.backup" ]; then
        cp "$backup_dir/apache_config.backup" "$config"
        print_success "Конфиг восстановлен"
    fi
    
    # Перезагружаем Apache
    apache2ctl graceful 2>/dev/null || systemctl reload apache2 2>/dev/null || true
    
    print_error "Конфигурация откачена к предыдущему состоянию"
}

###############################################################################
# Интерактивные вопросы
###############################################################################

ask_nextcloud_path() {
    local detected="$1"
    local default_path="${detected:-/var/www/html/nextcloud}"
    
    echo ""
    print_info "Nextcloud обнаружен в: $default_path"
    read -p "Путь к Nextcloud [$default_path]: " user_path
    NEXTCLOUD_PATH="${user_path:-$default_path}"
    
    # Проверка
    if [ ! -f "$NEXTCLOUD_PATH/occ" ]; then
        print_error "В указанном пути отсутствует occ. Проверьте правильность."
        ask_nextcloud_path "$detected"
        return
    fi
    
    print_success "Nextcloud найден: $NEXTCLOUD_PATH"
}

ask_apache_config() {
    print_info "Поиск конфигов Apache с SSL..."
    
    local configs=()
    while IFS= read -r line; do
        [ -n "$line" ] && configs+=("$line")
    done < <(find_apache_ssl_configs)
    
    if [ ${#configs[@]} -eq 0 ]; then
        print_error "Не найдено конфигов Apache с SSL"
        exit 1
    fi
    
    echo ""
    print_info "Найдено конфигов: ${#configs[@]}"
    for i in "${!configs[@]}"; do
        echo "   $((i+1))) ${configs[$i]}"
        
        # Показываем домены из конфига
        local domains=$(get_domains_from_config "${configs[$i]}")
        if [ -n "$domains" ]; then
            echo "      Домены: $domains"
        fi
    done
    echo "   0) Указать свой путь"
    echo ""
    
    while true; do
        read -p "Выберите конфиг [1-${#configs[@]}]: " config_choice
        
        if [ "$config_choice" -eq 0 ]; then
            read -p "Путь к конфиг Apache: " APACHE_CONFIG
            break
        elif [ "$config_choice" -ge 1 ] && [ "$config_choice" -le "${#configs[@]}" ]; then
            APACHE_CONFIG="${configs[$((config_choice-1))]}"
            break
        else
            print_error "Неверный выбор"
        fi
    done
    
    # Проверка существования
    if [ ! -f "$APACHE_CONFIG" ]; then
        print_error "Конфиг не найден: $APACHE_CONFIG"
        ask_apache_config
        return
    fi
    
    print_success "Конфиг Apache: $APACHE_CONFIG"
    
    # Показываем домены
    local domains=$(get_domains_from_config "$APACHE_CONFIG")
    if [ -n "$domains" ]; then
        print_info "Домены в конфиге: $domains"
    fi
}

ask_1c_server() {
    echo ""
    print_info "Укажите адрес 1С сервера для проксирования"
    echo "Формат: https://10.72.1.5 или http://192.168.1.100"
    echo ""
    
    read -p "Адрес 1С сервера [https://10.72.1.5]: " one_c_url
    ONE_C_SERVER="${one_c_url:-https://10.72.1.5}"
    
    # Валидация
    if [[ ! "$ONE_C_SERVER" =~ ^https?:// ]]; then
        print_error "URL должен начинаться с http:// или https://"
        ask_1c_server
        return
    fi
    
    print_success "1С сервер: $ONE_C_SERVER"
    
    # Определяем WebSocket URL
    ONE_C_SERVER_WS=$(echo "$ONE_C_SERVER" | sed 's|https://|ws://|; s|http://|ws://|')
    print_info "WebSocket URL: $ONE_C_SERVER_WS"
}

ask_app_version() {
    echo ""
    print_info "Выберите версию приложения для установки:"
    echo "1) one_c_web_client (v1.0.0) - Базовая версия"
    echo "2) one_c_web_client_v3 (v3.1.1) - Динамический прокси (рекомендуется)"
    echo ""
    
    read -p "Выберите версию [1-2]: " version_choice
    case "$version_choice" in
        2)
            APP_NAME="one_c_web_client_v3"
            APP_VERSION="3.1.1"
            ;;
        *)
            APP_NAME="one_c_web_client"
            APP_VERSION="1.0.0"
            ;;
    esac
    
    print_success "Выбрана версия: $APP_NAME v$APP_VERSION"
}

###############################################################################
# Функции установки
###############################################################################

install_app_files() {
    local app_dest="$NEXTCLOUD_PATH/apps/$APP_NAME"
    
    print_step "2" "Копирование файлов приложения..."
    
    # Ищем архив с приложением
    local app_archive=""
    local search_paths=(
        "./one_c_web_client_v3_deploy.tar.gz"
        "./one_c_web_client_v3_full.tar.gz"
        "./one_c_v3_all.tar.gz"
        "/tmp/one_c_web_client_v3_deploy.tar.gz"
        "/tmp/one_c_web_client_v3_full.tar.gz"
    )
    
    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then
            app_archive="$path"
            break
        fi
    done
    
    # Если архив не найден, пробуем найти директорию с приложением
    if [ -z "$app_archive" ]; then
        local source_dirs=(
            "./one_c_web_client_v3_clean"
            "./one_c_web_client_v3"
            "./$APP_NAME"
        )
        
        for dir in "${source_dirs[@]}"; do
            if [ -d "$dir" ] && [ -f "$dir/appinfo/info.xml" ]; then
                app_source="$dir"
                break
            fi
        done
    fi
    
    # Создаем директорию приложения
    mkdir -p "$app_dest"
    
    # Копируем из архива или из директории
    if [ -n "$app_archive" ]; then
        print_info "Распаковка приложения из $app_archive..."
        local temp_dir=$(mktemp -d)
        tar -xzf "$app_archive" -C "$temp_dir"
        
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
            print_success "Файлы приложения скопированы из архива"
        else
            rm -rf "$temp_dir"
            print_error "Не удалось найти приложение в архиве"
            return 1
        fi
    elif [ -n "$app_source" ]; then
        print_info "Копирование из $app_source..."
        cp -r "$app_source"/* "$app_dest/"
        print_success "Файлы приложения скопированы"
    else
        print_error "Архив с приложением не найден!"
        print_info "Положите один из файлов рядом со скриптом:"
        echo "   - one_c_web_client_v3_deploy.tar.gz"
        echo "   - one_c_web_client_v3_full.tar.gz"
        echo "   - one_c_v3_all.tar.gz"
        return 1
    fi
    
    # Устанавливаем права
    chown -R www-data:www-data "$app_dest"
    chmod -R 755 "$app_dest"
    
    print_success "Права установлены"
}

configure_apache() {
    print_step "3" "Настройка Apache..."
    
    # Создаем резервную копию
    local backup_dir=$(backup_config "$APACHE_CONFIG")
    print_info "Резервная копия: $backup_dir"
    
    # Создаем временный файл
    local temp_config=$(mktemp)
    cp "$APACHE_CONFIG" "$temp_config"
    
    # Включаем модули
    print_info "Включение модулей Apache..."
    a2enmod proxy proxy_http proxy_wstunnel headers rewrite ssl 2>/dev/null || true
    
    # Проверяем что модули включены
    local missing_modules=$(check_apache_modules)
    if [ $? -eq 1 ]; then
        print_warning "Не удалось включить модули: $missing_modules"
        print_info "Попробуйте включить вручную: a2enmod $missing_modules"
    else
        print_success "Все модули Apache включены"
    fi
    
    # Проверяем, есть ли уже наши настройки
    if grep -q "ProxyPass.*one_c" "$APACHE_CONFIG" 2>/dev/null; then
        print_warning "Настройки one_c_web_client уже найдены в конфиге"
        read -p "Продолжить и добавить ещё раз? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            rm "$temp_config"
            print_info "Установка отменена"
            return 1
        fi
    fi
    
    # Находим VirtualHost *:443 для Nextcloud
    print_info "Поиск VirtualHost *:443 для Nextcloud..."
    
    # Используем awk для точного определения VirtualHost
    local vhost_info=$(awk '
    BEGIN {
        in_vhost = 0
        vhost_start = 0
        vhost_end = 0
        has_servername = 0
        found = 0
    }
    /<VirtualHost.*:443>/ {
        in_vhost = 1
        vhost_start = NR
        has_servername = 0
        next
    }
    in_vhost && /<\/VirtualHost>/ {
        vhost_end = NR
        if (has_servername > 0) {
            print vhost_start ":" vhost_end ":" has_servername
            found = 1
            exit
        }
        in_vhost = 0
        next
    }
    in_vhost && /ServerName|ServerAlias/ {
        has_servername = NR
    }
    END {
        if (!found) {
            print "0:0:0"
        }
    }
    ' "$APACHE_CONFIG")
    
    local vhost_start=$(echo "$vhost_info" | cut -d: -f1)
    local vhost_end=$(echo "$vhost_info" | cut -d: -f2)
    local servername_line=$(echo "$vhost_info" | cut -d: -f3)
    
    if [ "$vhost_start" -eq 0 ] || [ "$vhost_end" -eq 0 ]; then
        print_error "Не удалось найти VirtualHost *:443 в конфиге"
        rm "$temp_config"
        return 1
    fi
    
    print_success "Найден VirtualHost *:443 (строки $vhost_start-$vhost_end)"
    
    # Вставляем директивы перед закрывающим </VirtualHost>
    print_info "Добавление директив прокси для 1С..."
    
    # Создаем файл с директивами
    local directives_file=$(mktemp)
    cat > "$directives_file" << EOF

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

    # Прокси для 1С сервера: $ONE_C_SERVER
    ProxyPass /$APP_NAME $ONE_C_SERVER/$APP_NAME retry=0 timeout=60
    ProxyPassReverse /$APP_NAME $ONE_C_SERVER/$APP_NAME
    ProxyPassReverseCookiePath / /

    # WebSocket прокси для 1С
    ProxyPass /$APP_NAME/ws $ONE_C_SERVER_WS/$APP_NAME/ws retry=0 timeout=60
    ProxyPassReverse /$APP_NAME/ws $ONE_C_SERVER_WS/$APP_NAME/ws

    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # Конец настроек one_c_web_client_v3
    # ===================================================================

EOF
    
    # Вставляем директивы перед </VirtualHost>
    local line_before_end=$((vhost_end - 1))
    
    # Используем sed для вставки
    sed -i "${line_before_end}r $directives_file" "$temp_config"
    
    rm "$directives_file"
    
    # Проверяем синтаксис
    print_info "Проверка синтаксиса Apache..."
    if apache2ctl -t -f "$temp_config" 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
        
        # Копируем изменённый конфиг
        cp "$temp_config" "$APACHE_CONFIG"
        print_success "Конфиг Apache обновлён"
    else
        print_error "Ошибка синтаксиса Apache!"
        apache2ctl -t -f "$temp_config" 2>&1 | head -10
        
        # Восстанавливаем резервную копию
        restore_backup "$backup_dir" "$APACHE_CONFIG"
        rm "$temp_config"
        return 1
    fi
    
    rm "$temp_config"
}

install_nextcloud_app() {
    print_step "4" "Установка приложения в Nextcloud..."
    
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

restart_apache() {
    print_step "5" "Перезапуск Apache (graceful)..."
    
    # Проверяем синтаксис ещё раз
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        # Используем graceful вместо restart
        if apache2ctl graceful 2>/dev/null; then
            print_success "Apache перезапущен (graceful)"
        elif systemctl reload apache2 2>/dev/null; then
            print_success "Apache перезапущен (systemctl reload)"
        else
            print_error "Не удалось перезапустить Apache"
            return 1
        fi
    else
        print_error "Ошибка синтаксиса Apache после установки"
        apache2ctl configtest
        return 1
    fi
}

###############################################################################
# Проверка установки
###############################################################################

verify_installation() {
    print_step "6" "Проверка установки..."
    
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
    
    # Проверка модулей
    local missing=$(check_apache_modules)
    if [ $? -eq 0 ]; then
        print_success "Все необходимые модули Apache включены"
    else
        print_warning "Отсутствуют модули: $missing"
    fi
    
    return $errors
}

###############################################################################
# Вывод результатов
###############################################################################

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
    echo "   https://your-nextcloud-domain/index.php/settings/admin/$APP_NAME"
    echo ""
    echo "2. Добавьте базы 1С через интерфейс"
    echo ""
    echo "3. Проверьте работу приложения:"
    echo "   https://your-nextcloud-domain/index.php/apps/$APP_NAME/"
    echo ""
    
    echo -e "${YELLOW}⚠  Важно:${NC}"
    echo "   - Убедитесь, что 1С сервер доступен с сервера Nextcloud"
    echo "   - Проверьте CORS и CSP настройки на 1С сервере"
    echo "   - Резервная копия сохранена: /tmp/one_c_backup_*/"
    echo ""
    
    echo -e "${GREEN}✓ Установка завершена. Рекомендуется проверить работу прокси${NC}"
    echo -e "${GREEN}  и при необходимости отредактировать конфиг вручную.${NC}"
    echo ""
}

###############################################################################
# Обработчик ошибок
###############################################################################

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Установка прервана с ошибкой: $exit_code"
        print_info "Лог установки: $LOG_FILE"
    fi
}

trap cleanup EXIT

###############################################################################
# Основная функция
###############################################################################

main() {
    print_header
    
    print_info "Сбор информации о сервере..."
    
    # Автоопределение
    NC_PATH_DETECTED=$(find_nextcloud_path)
    
    if [ -z "$NC_PATH_DETECTED" ]; then
        print_error "Nextcloud не найден"
        exit 1
    fi
    
    # Интерактивные вопросы
    ask_nextcloud_path "$NC_PATH_DETECTED"
    ask_apache_config
    ask_1c_server
    ask_app_version
    
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
    
    echo -e "${GREEN}✓ Установка завершена!${NC}"
}

# Запуск
main "$@"
