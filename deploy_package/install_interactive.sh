#!/bin/bash

###############################################################################
# one_c_web_client - Интерактивный установщик
# Интеграция 1С:Предприятие с Nextcloud
# Версия: 3.1.0 - Интерактивная установка с автоопределением
# Дата: Март 2026
###############################################################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Без цвета

# Логирование
LOG_FILE="/tmp/one_c_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

###############################################################################
# Функции вывода
###############################################################################
print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   one_c_web_client - Интерактивный установщик             ║"
    echo "║   Интеграция 1С:Предприятие с Nextcloud                   ║"
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
    
    # Поиск через find
    local found=$(find /var/www -name "occ" -type f 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        dirname "$found"
        return 0
    fi
    
    return 1
}

# Найти конфиг Apache
find_apache_config() {
    local configs=(
        "/etc/apache2/sites-available/nextcloud.conf"
        "/etc/apache2/sites-available/nextcloud-le-ssl.conf"
        "/etc/apache2/sites-available/000-default-le-ssl.conf"
        "/etc/apache2/sites-enabled/nextcloud.conf"
        "/etc/apache2/sites-enabled/000-default.conf"
        "/etc/httpd/conf.d/nextcloud.conf"
    )
    
    for config in "${configs[@]}"; do
        if [ -f "$config" ] && grep -q "nextcloud\|DocumentRoot.*nextcloud" "$config" 2>/dev/null; then
            echo "$config"
            return 0
        fi
    done
    
    return 1
}

# Проверить SSL сертификаты
check_ssl_config() {
    local config="$1"
    local cert_file=""
    local key_file=""
    local has_letsencrypt=false
    local cert_path=""
    
    # Извлекаем пути к сертификатам из конфига
    if [ -f "$config" ]; then
        cert_file=$(grep -i "SSLCertificateFile" "$config" 2>/dev/null | awk '{print $2}' | head -1)
        key_file=$(grep -i "SSLCertificateKeyFile" "$config" 2>/dev/null | awk '{print $2}' | head -1)
        
        # Проверяем Let's Encrypt
        if echo "$cert_file" | grep -qi "letsencrypt\|certbot"; then
            has_letsencrypt=true
            # Путь к директории сертификатов
            cert_path=$(dirname "$cert_file")
        fi
    fi
    
    echo "$cert_file|$key_file|$has_letsencrypt|$cert_path"
}

# Получить доменное имя из конфига Apache
get_server_domain() {
    local config="$1"
    local domain=""
    
    if [ -f "$config" ]; then
        domain=$(grep -i "ServerName" "$config" 2>/dev/null | awk '{print $2}' | head -1)
    fi
    
    # Если не найдено, пробуем hostname
    if [ -z "$domain" ]; then
        domain=$(hostname -f 2>/dev/null || hostname)
    fi
    
    echo "$domain"
}

# Проверить модули Apache
check_apache_modules() {
    local required_modules=("proxy" "proxy_http" "rewrite" "headers" "ssl")
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

# Найти 1C серверы в сети (опционально)
scan_1c_servers() {
    print_info "Сканирование сети на наличие 1С серверов..."
    local servers=()
    
    # Проверяем популярные адреса
    local common_ips=(
        "10.72.1.5"
        "10.72.1.6"
        "192.168.1.100"
        "192.168.0.100"
        "localhost"
    )
    
    for ip in "${common_ips[@]}"; do
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            if curl -k -s --connect-timeout 2 "https://$ip" &>/dev/null || curl -s --connect-timeout 2 "http://$ip" &>/dev/null; then
                servers+=("$ip")
                print_info "Найден потенциальный 1С сервер: $ip"
            fi
        fi
    done
    
    echo "${servers[@]}"
}

###############################################################################
# Интерактивные вопросы
###############################################################################

ask_nextcloud_path() {
    local detected="$1"
    local default_path="${detected:-/var/www/nextcloud}"
    
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
    local detected="$1"
    local default_config="${detected:-/etc/apache2/sites-available/nextcloud.conf}"
    
    echo ""
    print_info "Конфиг Apache: $default_config"
    read -p "Путь к конфиг Apache [$default_config]: " user_config
    APACHE_CONFIG="${user_config:-$default_config}"
    
    # Если файл не существует, создадим
    if [ ! -f "$APACHE_CONFIG" ]; then
        print_info "Конфиг не найден, будет создан новый"
    fi
    
    print_success "Конфиг Apache: $APACHE_CONFIG"
}

ask_domain() {
    local detected="$1"
    local default_domain="${detected:-$(hostname -f 2>/dev/null || echo 'cloud.example.com')}"
    
    echo ""
    print_info "Домен сервера: $default_domain"
    read -p "Доменное имя Nextcloud [$default_domain]: " user_domain
    DOMAIN="${user_domain:-$default_domain}"
    
    print_success "Домен: $DOMAIN"
}

ask_ssl_certs() {
    local ssl_info="$1"
    IFS='|' read -r cert_file key_file is_letsencrypt cert_path <<< "$ssl_info"
    
    echo ""
    if [ "$is_letsencrypt" = "true" ]; then
        print_success "Обнаружен Let's Encrypt SSL"
        print_info "Сертификаты в: $cert_path"
        SSL_CERT_FILE="$cert_file"
        SSL_KEY_FILE="$key_file"
    else
        print_info "SSL сертификаты:"
        read -p "Путь к SSL сертификату [$cert_file]: " user_cert
        SSL_CERT_FILE="${user_cert:-$cert_file}"
        read -p "Путь к SSL ключу [$key_file]: " user_key
        SSL_KEY_FILE="${user_key:-$key_file}"
    fi
    
    # Проверка существования
    if [ ! -f "$SSL_CERT_FILE" ]; then
        print_error "SSL сертификат не найден: $SSL_CERT_FILE"
        SSL_CERT_FILE=""
    fi
    if [ ! -f "$SSL_KEY_FILE" ]; then
        print_error "SSL ключ не найден: $SSL_KEY_FILE"
        SSL_KEY_FILE=""
    fi
}

ask_1c_servers() {
    echo ""
    print_header "Настройка 1С серверов"
    echo ""
    print_info "Укажите адрес 1С сервера для проксирования"
    echo "Формат: https://10.72.1.5 или http://192.168.1.100"
    echo ""
    
    read -p "Адрес 1С сервера [https://10.72.1.5]: " one_c_url
    ONE_C_SERVER="${one_c_url:-https://10.72.1.5}"
    
    # Валидация
    if [[ ! "$ONE_C_SERVER" =~ ^https?:// ]]; then
        print_error "URL должен начинаться с http:// или https://"
        ask_1c_servers
        return
    fi
    
    print_success "1С сервер: $ONE_C_SERVER"
    
    # Спрашиваем идентификаторы баз
    echo ""
    print_info "Добавьте идентификаторы баз 1С (как в адресной строке 1С)"
    echo "Например: buh, zup, ut и т.д."
    echo "Вводите по одному, пустая строка - завершение"
    
    ONE_C_BASES=()
    while true; do
        read -p "База 1С (Enter для завершения): " base
        [ -z "$base" ] && break
        ONE_C_BASES+=("$base")
        print_info "Добавлено: $base"
    done
    
    if [ ${#ONE_C_BASES[@]} -eq 0 ]; then
        print_info "Базы не указаны, будет настроен прокси для всех путей"
        ONE_C_BASES=("*")
    fi
}

ask_app_version() {
    echo ""
    print_info "Выберите версию приложения для установки:"
    echo "1) one_c_web_client (v1.0.0) - Базовая версия"
    echo "2) one_c_web_client_v3 (v3.0.0) - Динамический прокси (рекомендуется)"
    echo ""
    
    read -p "Выберите версию [1-2]: " version_choice
    case "$version_choice" in
        2)
            APP_NAME="one_c_web_client_v3"
            APP_VERSION="3.0.0"
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

backup_config() {
    if [ -f "$APACHE_CONFIG" ]; then
        local backup="${APACHE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$APACHE_CONFIG" "$backup"
        print_success "Резервная копия конфига: $backup"
        echo "$backup"
    fi
}

install_app_files() {
    local app_source="$1"
    local app_dest="$NEXTCLOUD_PATH/apps/$APP_NAME"
    
    print_step "2" "Копирование файлов приложения..."
    
    # Создаем директорию
    mkdir -p "$app_dest"
    
    # Копируем файлы
    if [ -d "$app_source" ]; then
        cp -r "$app_source"/* "$app_dest/"
    else
        print_error "Исходная директория не найдена: $app_source"
        return 1
    fi
    
    # Устанавливаем права
    chown -R www-data:www-data "$app_dest"
    chmod -R 755 "$app_dest"
    
    print_success "Файлы приложения скопированы"
}

configure_apache() {
    print_step "3" "Настройка Apache..."
    
    # Создаем резервную копию
    local backup=$(backup_config)
    
    # Определяем тип конфига (полный VirtualHost или дополнение)
    if grep -q "<VirtualHost" "$APACHE_CONFIG" 2>/dev/null; then
        # Полный конфиг - дополняем существующий
        configure_apache_full
    else
        # Простой конфиг - создаем новый
        configure_apache_simple
    fi
    
    # Включаем модули
    print_info "Включение модулей Apache..."
    a2enmod proxy proxy_http rewrite headers ssl 2>/dev/null || true
    print_success "Модули Apache включены"
}

configure_apache_full() {
    # Дополняем существующий VirtualHost
    print_info "Дополнение существующего VirtualHost..."
    
    # Создаем временный файл с новыми директивами
    local temp_conf=$(mktemp)
    
    # Читаем оригинал
    cat "$APACHE_CONFIG" > "$temp_conf"
    
    # Добавляем настройки прокси перед закрывающим </VirtualHost>
    if ! grep -q "ProxyPass.*one_c" "$APACHE_CONFIG" 2>/dev/null; then
        # Добавляем перед </VirtualHost>
        sed -i "/<\/VirtualHost>/i \\
    # one_c_web_client - Прокси для 1С\\
    SSLProxyEngine on\\
    SSLProxyVerify none\\
    SSLProxyCheckPeerCN off\\
    SSLProxyCheckPeerName off\\
\\
    # Исключения для статических файлов Nextcloud\\
    ProxyPass /core !\\
    ProxyPass /apps !\\
    ProxyPass /dist !\\
    ProxyPass /js !\\
    ProxyPass /css !\\
    ProxyPass /l10n !\\
    ProxyPass /index.php !\\
\\
    # Прокси для 1С сервера: $ONE_C_SERVER\\
    ProxyPass /$APP_NAME $ONE_C_SERVER/$APP_NAME retry=0 timeout=60\\
    ProxyPassReverse /$APP_NAME $ONE_C_SERVER/$APP_NAME\\
\\
    # Разрешение фреймов\\
    Header unset X-Frame-Options\\
    Header always set Content-Security-Policy \"frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;\"
" "$temp_conf"
    fi
    
    # Проверяем синтаксис
    if apache2ctl -t -f "$temp_conf" 2>&1 | grep -q "Syntax OK"; then
        cp "$temp_conf" "$APACHE_CONFIG"
        print_success "Конфиг Apache обновлен"
    else
        print_error "Ошибка в конфигурации Apache"
        cat "$temp_conf"
        rm "$temp_conf"
        return 1
    fi
    
    rm "$temp_conf"
}

configure_apache_simple() {
    # Создаем новый конфиг
    print_info "Создание нового конфига Apache..."
    
    cat > "$APACHE_CONFIG" << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    Redirect permanent / https://$DOMAIN/
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $NEXTCLOUD_PATH

    SSLEngine on
    SSLCertificateFile $SSL_CERT_FILE
    SSLCertificateKeyFile $SSL_KEY_FILE

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

    # one_c_web_client - Прокси для 1С: $ONE_C_SERVER
    ProxyPass /$APP_NAME $ONE_C_SERVER/$APP_NAME retry=0 timeout=60
    ProxyPassReverse /$APP_NAME $ONE_C_SERVER/$APP_NAME
    ProxyPassReverseCookiePath / /

    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    <Directory $NEXTCLOUD_PATH>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>
</VirtualHost>
EOF
    
    print_success "Конфиг Apache создан"
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
    print_step "5" "Перезапуск Apache..."
    
    # Проверяем синтаксис
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        systemctl reload apache2
        print_success "Apache перезапущен"
    else
        print_error "Ошибка синтаксиса Apache"
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
        ((errors++))
    fi
    
    # Проверка конфига
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Конфигурация Apache корректна"
    else
        print_error "Ошибка в конфигурации Apache"
        ((errors++))
    fi
    
    # Проверка SSL
    if [ -n "$SSL_CERT_FILE" ] && [ -f "$SSL_CERT_FILE" ]; then
        print_success "SSL сертификат найден"
    else
        print_info "SSL сертификат не проверялся"
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
    echo "  Домен:          $DOMAIN"
    echo "  1С сервер:      $ONE_C_SERVER"
    echo ""
    
    echo -e "${BLUE}📋 Следующие шаги:${NC}"
    echo ""
    echo "1. Откройте админ-панель Nextcloud:"
    echo "   https://$DOMAIN/index.php/settings/admin"
    echo ""
    echo "2. Настройте базы 1С в разделе \"Администрирование\" → \"1C WebClient\""
    echo ""
    echo "3. Проверьте работу приложения:"
    echo "   https://$DOMAIN/index.php/apps/$APP_NAME/"
    echo ""
    
    if [ ${#ONE_C_BASES[@]} -gt 0 ] && [ "${ONE_C_BASES[0]}" != "*" ]; then
        echo "4. Настроенные базы 1С:"
        for base in "${ONE_C_BASES[@]}"; do
            echo "   - $base"
        done
        echo ""
    fi
    
    echo "5. Лог установки: $LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}⚠  Важно:${NC}"
    echo "   - Убедитесь, что 1С сервер доступен с сервера Nextcloud"
    echo "   - Проверьте CORS и CSP настройки на 1С сервере"
    echo "   - При проблемах смотрите лог: $LOG_FILE"
    echo ""
}

###############################################################################
# Основная функция
###############################################################################

main() {
    print_header
    
    # Проверка прав
    if [ "$EUID" -ne 0 ]; then
        print_error "Ошибка: Запустите скрипт от root (sudo ./install_interactive.sh)"
        exit 1
    fi
    
    print_info "Сбор информации о сервере..."
    
    # Автоопределение
    NC_PATH_DETECTED=$(find_nextcloud_path)
    APACHE_CONFIG_DETECTED=$(find_apache_config)
    DOMAIN_DETECTED=$(get_server_domain "$APACHE_CONFIG_DETECTED")
    SSL_INFO=$(check_ssl_config "$APACHE_CONFIG_DETECTED")
    
    # Проверка модулей Apache
    MISSING_MODULES=$(check_apache_modules)
    if [ $? -eq 1 ]; then
        print_info "Отсутствуют модули Apache: $MISSING_MODULES"
        print_info "Они будут включены в процессе установки"
    fi
    
    # Интерактивные вопросы
    ask_nextcloud_path "$NC_PATH_DETECTED"
    ask_apache_config "$APACHE_CONFIG_DETECTED"
    ask_domain "$DOMAIN_DETECTED"
    ask_ssl_certs "$SSL_INFO"
    ask_1c_servers
    ask_app_version
    
    # Установка
    echo ""
    print_header "Начало установки"
    echo ""
    
    install_app_files "/home/smidt/nc1c/$APP_NAME"
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
