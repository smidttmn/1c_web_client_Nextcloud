#!/bin/bash
# ============================================================================
# one_c_web_client - Скрипт автоматической установки приложения
# ============================================================================
# Этот скрипт автоматически установит приложение 1C WebClient в Nextcloud
# 
# Использование:
#   ./deploy.sh [путь_к_архиву]
# 
# Пример:
#   ./deploy.sh one_c_web_client_deploy.tar.gz
# ============================================================================

set -e  # Остановить выполнение при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Без цвета

# ============================================================================
# Функции для вывода сообщений
# ============================================================================

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================"
    echo " $1"
    echo "============================================================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ Ошибка: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Проверка прав суперпользователя
# ============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Скрипт должен быть запущен от имени root"
        print_info "Используйте: sudo $0 $@"
        exit 1
    fi
}

# ============================================================================
# Проверка зависимостей
# ============================================================================

check_dependencies() {
    print_header "Проверка зависимостей"
    
    local missing_deps=()
    
    # Проверка tar
    if ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    # Проверка curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Проверка php
    if ! command -v php &> /dev/null; then
        missing_deps+=("php")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Отсутствуют необходимые пакеты: ${missing_deps[*]}"
        print_info "Установите их командой:"
        print_info "  apt-get install ${missing_deps[*]}  # для Debian/Ubuntu"
        print_info "  yum install ${missing_deps[*]}      # для CentOS/RHEL"
        exit 1
    fi
    
    print_success "Все зависимости установлены"
}

# ============================================================================
# Автоматическое определение пути к Nextcloud
# ============================================================================

find_nextcloud_path() {
    print_header "Поиск установки Nextcloud"
    
    # Популярные пути к Nextcloud
    local common_paths=(
        "/var/www/nextcloud"
        "/var/www/html/nextcloud"
        "/srv/www/nextcloud"
        "/srv/http/nextcloud"
        "/usr/share/webapps/nextcloud"
        "/opt/nextcloud"
    )
    
    # Проверяем распространенные пути
    for path in "${common_paths[@]}"; do
        if [ -f "$path/occ" ]; then
            print_success "Nextcloud найден: $path"
            NC_PATH="$path"
            return 0
        fi
    done
    
    # Если не найдено, спрашиваем пользователя
    print_warning "Nextcloud не найден в стандартных расположениях"
    
    while true; do
        read -p "Введите полный путь к Nextcloud (например, /var/www/nextcloud): " NC_PATH
        
        # Проверяем, существует ли occ
        if [ -f "$NC_PATH/occ" ]; then
            print_success "Nextcloud найден: $NC_PATH"
            return 0
        else
            print_error "В указанном пути не найден файл occ"
            print_info "Проверьте правильность пути или установите Nextcloud"
        fi
        
        # Предлагаем продолжить поиск
        read -p "Продолжить поиск? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            print_error "Установка прервана"
            exit 1
        fi
    done
}

# ============================================================================
# Проверка версии Nextcloud
# ============================================================================

check_nextcloud_version() {
    print_header "Проверка версии Nextcloud"
    
    # Получаем версию через occ
    local version
    version=$(sudo -u www-data php "$NC_PATH/occ" status --output=json 2>/dev/null | grep -o '"versionstring":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$version" ]; then
        print_warning "Не удалось определить версию Nextcloud"
        read -p "Продолжить установку? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        return 0
    fi
    
    print_info "Версия Nextcloud: $version"
    
    # Извлекаем основную версию (первое число)
    local major_version
    major_version=$(echo "$version" | cut -d'.' -f1)
    
    # Проверяем совместимость (31 или 32)
    if [ "$major_version" -eq 31 ] || [ "$major_version" -eq 32 ]; then
        print_success "Версия Nextcloud совместима"
    else
        print_warning "Версия Nextcloud ($version) может быть несовместима"
        print_info "Приложение тестировалось на версиях 31 и 32"
        read -p "Продолжить установку? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# ============================================================================
# Проверка веб-сервера
# ============================================================================

check_web_server() {
    print_header "Определение веб-сервера"
    
    if systemctl is-active --quiet apache2; then
        WEB_SERVER="apache2"
        print_success "Обнаружен Apache"
    elif systemctl is-active --quiet nginx; then
        WEB_SERVER="nginx"
        print_success "Обнаружен Nginx"
    elif systemctl is-active --quiet httpd; then
        WEB_SERVER="httpd"
        print_success "Обнаружен HTTPD"
    else
        print_warning "Веб-сервер не обнаружен или не запущен"
        WEB_SERVER="unknown"
    fi
}

# ============================================================================
# Проверка доступности HTTPS на сервере 1С
# ============================================================================

check_https_availability() {
    print_header "Проверка доступности HTTPS"
    
    echo ""
    print_info "Для работы приложения 1С должна быть доступна по HTTPS"
    echo ""
    read -p "Введите URL вашей базы 1С (например, https://192.168.1.100/base1c/): " ONEC_URL
    
    if [ -z "$ONEC_URL" ]; then
        print_warning "URL не введен, пропускаем проверку"
        return 0
    fi
    
    print_info "Проверяем доступность: $ONEC_URL"
    
    # Проверяем доступность с игнорированием сертификатов
    if curl -k --connect-timeout 5 -s -o /dev/null -w "%{http_code}" "$ONEC_URL" | grep -q "200\|301\|302"; then
        print_success "Сервер 1С доступен по HTTPS"
    else
        print_error "Сервер 1С недоступен по HTTPS"
        print_warning "Возможные причины:"
        echo "  1. На сервере 1С не настроен HTTPS"
        echo "  2. Сервер 1С недоступен из сети этого сервера"
        echo "  3. Неверный URL"
        echo ""
        read -p "Продолжить установку? (Приложение не будет работать без HTTPS) (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# ============================================================================
# Распаковка приложения
# ============================================================================

extract_application() {
    print_header "Распаковка приложения"
    
    local archive_path="$1"
    
    # Проверяем существование архива
    if [ ! -f "$archive_path" ]; then
        print_error "Архив не найден: $archive_path"
        exit 1
    fi
    
    print_info "Источник: $archive_path"
    
    # Определяем директорию apps
    local apps_dir="$NC_PATH/apps"
    
    if [ ! -d "$apps_dir" ]; then
        print_error "Директория apps не найдена: $apps_dir"
        exit 1
    fi
    
    # Распаковываем архив во временную директорию
    local temp_dir=$(mktemp -d)
    print_info "Распаковка во временную директорию: $temp_dir"
    
    tar -xzf "$archive_path" -C "$temp_dir"
    
    # Ищем директорию с приложением (может называться nc1c или one_c_web_client)
    local app_source_dir=""
    
    if [ -d "$temp_dir/one_c_web_client" ]; then
        app_source_dir="$temp_dir/one_c_web_client"
        print_info "Найдена директория: one_c_web_client"
    elif [ -d "$temp_dir/nc1c" ]; then
        app_source_dir="$temp_dir/nc1c"
        print_info "Найдена директория: nc1c"
    else
        # Если архив содержит только файлы приложения без корневой директории
        app_source_dir="$temp_dir"
        print_warning "Корневая директория приложения не найдена, используем $temp_dir"
    fi
    
    # Копируем приложение в директорию apps
    print_info "Копирование приложения в $apps_dir"
    cp -r "$app_source_dir" "$apps_dir/one_c_web_client"
    
    # Очищаем временную директорию
    rm -rf "$temp_dir"
    
    print_success "Приложение распаковано"
}

# ============================================================================
# Установка прав доступа
# ============================================================================

set_permissions() {
    print_header "Установка прав доступа"
    
    local app_dir="$NC_PATH/apps/one_c_web_client"
    
    # Определяем владельца веб-сервера
    local web_user="www-data"
    
    # Проверяем, существует ли пользователь
    if ! id "$web_user" &>/dev/null; then
        # Пробуем альтернативные имена
        if id "apache" &>/dev/null; then
            web_user="apache"
        elif id "http" &>/dev/null; then
            web_user="http"
        else
            print_warning "Не удалось определить пользователя веб-сервера"
            read -p "Введите имя пользователя веб-сервера: " web_user
        fi
    fi
    
    print_info "Владелец веб-сервера: $web_user"
    print_info "Директория приложения: $app_dir"
    
    # Устанавливаем владельца
    print_info "Установка владельца файлов..."
    chown -R "$web_user:$web_user" "$app_dir"
    print_success "Владелец установлен"
    
    # Устанавливаем права на директории
    print_info "Установка прав на директории (755)..."
    find "$app_dir" -type d -exec chmod 755 {} \;
    print_success "Права на директории установлены"
    
    # Устанавливаем права на файлы
    print_info "Установка прав на файлы (644)..."
    find "$app_dir" -type f -exec chmod 644 {} \;
    print_success "Права на файлы установлены"
}

# ============================================================================
# Установка приложения через OCC
# ============================================================================

install_via_occ() {
    print_header "Установка приложения через OCC"
    
    local occ="$NC_PATH/occ"
    
    # Проверяем существование occ
    if [ ! -f "$occ" ]; then
        print_error "Файл occ не найден: $occ"
        exit 1
    fi
    
    # Определяем пользователя веб-сервера
    local web_user="www-data"
    if ! id "$web_user" &>/dev/null; then
        web_user="apache"
    fi
    
    # Отключаем приложение, если оно уже установлено
    print_info "Проверка существующей установки..."
    if sudo -u "$web_user" php "$occ" app:list 2>/dev/null | grep -q "one_c_web_client"; then
        print_warning "Приложение уже установлено, отключаем старую версию"
        sudo -u "$web_user" php "$occ" app:disable one_c_web_client || true
    fi
    
    # Устанавливаем приложение
    print_info "Установка приложения..."
    if sudo -u "$web_user" php "$occ" app:install one_c_web_client; then
        print_success "Приложение установлено"
    else
        print_error "Не удалось установить приложение через OCC"
        print_info "Попробуйте установить вручную:"
        print_info "  sudo -u $web_user php $occ app:install one_c_web_client"
        exit 1
    fi
    
    # Включаем приложение
    print_info "Включение приложения..."
    if sudo -u "$web_user" php "$occ" app:enable one_c_web_client; then
        print_success "Приложение включено"
    else
        print_warning "Не удалось включить приложение (возможно, оно уже включено)"
    fi
    
    # Очищаем кэш
    print_info "Очистка кэша Nextcloud..."
    if sudo -u "$web_user" php "$occ" maintenance:repair; then
        print_success "Кэш очищен"
    else
        print_warning "Не удалось очистить кэш"
    fi
}

# ============================================================================
# Настройка CSP (опционально)
# ============================================================================

configure_csp() {
    print_header "Настройка Content Security Policy"
    
    echo ""
    print_info "CSP необходим, если 1С находится на другом домене"
    echo ""
    read -p "Настроить CSP? (y/n): " choice
    
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        print_info "Настройка CSP пропущена"
        return 0
    fi
    
    local controller_file="$NC_PATH/apps/one_c_web_client/lib/Controller/PageController.php"
    
    if [ ! -f "$controller_file" ]; then
        print_error "Файл контроллера не найден: $controller_file"
        return 1
    fi
    
    echo ""
    print_info "Введите домены 1С (по одному, пустая строка для завершения):"
    
    local domains=()
    while true; do
        read -p "Домен 1С (например, https://192.168.1.100): " domain
        
        if [ -z "$domain" ]; then
            break
        fi
        
        domains+=("$domain")
    done
    
    if [ ${#domains[@]} -eq 0 ]; then
        print_info "Домены не введены, настройка CSP пропущена"
        return 0
    fi
    
    # Создаем резервную копию
    cp "$controller_file" "$controller_file.backup"
    print_info "Резервная копия создана: $controller_file.backup"
    
    # Добавляем домены в контроллер
    print_info "Добавление доменов в контроллер..."
    
    # Находим строку с ContentSecurityPolicy и добавляем домены после неё
    for domain in "${domains[@]}"; do
        # Добавляем allowedFrameDomain
        sed -i "/\$csp = new ContentSecurityPolicy()/a \\    \$csp->addAllowedFrameDomain('$domain');" "$controller_file"
        
        # Добавляем allowedScriptDomain (для динамических скриптов 1С)
        sed -i "/\$csp = new ContentSecurityPolicy()/a \\    \$csp->addAllowedScriptDomain('$domain');" "$controller_file"
    done
    
    print_success "Домены добавлены в контроллер"
    
    # Очищаем кэш
    print_info "Очистка кэша..."
    local web_user="www-data"
    if ! id "$web_user" &>/dev/null; then
        web_user="apache"
    fi
    sudo -u "$web_user" php "$NC_PATH/occ" maintenance:repair
    
    print_success "CSP настроен"
}

# ============================================================================
# Вывод итоговой информации
# ============================================================================

print_summary() {
    print_header "Установка завершена"
    
    echo ""
    print_success "Приложение 1C WebClient успешно установлено!"
    echo ""
    print_info "Следующие шаги:"
    echo ""
    echo "1. Откройте Nextcloud в браузере:"
    echo "   https://$(hostname -f 2>/dev/null || echo 'ваш-домен')"
    echo ""
    echo "2. Войдите под учетной записью администратора"
    echo ""
    echo "3. Перейдите в настройки:"
    echo "   Настройки → Администрирование → 1C WebClient"
    echo ""
    echo "4. Добавьте базы 1С:"
    echo "   - Нажмите 'Добавить базу'"
    echo "   - Введите название (например, 'Бухгалтерия')"
    echo "   - Введите URL (например, 'https://192.168.1.100/buh/')"
    echo "   - Нажмите 'Сохранить'"
    echo ""
    echo "5. Проверьте работу приложения:"
    echo "   - Откройте меню приложений"
    echo "   - Выберите '1C WebClient'"
    echo "   - Нажмите на кнопку базы 1С"
    echo ""
    
    if [ -n "$ONEC_URL" ]; then
        print_info "Проверка доступности 1С:"
        echo "   URL: $ONEC_URL"
        echo "   Статус: проверен"
    fi
    
    echo ""
    print_info "Путь к Nextcloud: $NC_PATH"
    print_info "Директория приложения: $NC_PATH/apps/one_c_web_client"
    echo ""
    
    if [ "$WEB_SERVER" != "unknown" ]; then
        print_info "Веб-сервер: $WEB_SERVER"
        
        if [ "$WEB_SERVER" = "apache2" ] || [ "$WEB_SERVER" = "httpd" ]; then
            echo ""
            print_info "Если возникнут проблемы с CSP, перезапустите Apache:"
            echo "   systemctl restart apache2"
        elif [ "$WEB_SERVER" = "nginx" ]; then
            echo ""
            print_info "Если возникнут проблемы с CSP, перезапустите Nginx:"
            echo "   systemctl restart nginx"
        fi
    fi
    
    echo ""
    echo "============================================================================"
    echo ""
}

# ============================================================================
# Основная функция
# ============================================================================

main() {
    print_header "OneC WebClient - Автоматическая установка"
    
    echo ""
    echo "Этот скрипт автоматически установит приложение 1C WebClient в Nextcloud"
    echo ""
    
    # Проверка прав root
    check_root
    
    # Проверка зависимостей
    check_dependencies
    
    # Поиск пути к Nextcloud
    find_nextcloud_path
    
    # Проверка версии Nextcloud
    check_nextcloud_version
    
    # Определение веб-сервера
    check_web_server
    
    # Проверка доступности HTTPS
    check_https_availability
    
    # Получение пути к архиву
    local archive_path="${1:-}"
    
    if [ -z "$archive_path" ]; then
        # Ищем архив в текущей директории
        if [ -f "one_c_web_client_deploy.tar.gz" ]; then
            archive_path="one_c_web_client_deploy.tar.gz"
            print_info "Найден архив: $archive_path"
        else
            print_error "Архив не указан и не найден в текущей директории"
            print_info "Использование: $0 [путь_к_архиву]"
            exit 1
        fi
    fi
    
    # Распаковка приложения
    extract_application "$archive_path"
    
    # Установка прав
    set_permissions
    
    # Установка через OCC
    install_via_occ
    
    # Настройка CSP (опционально)
    configure_csp
    
    # Вывод итогов
    print_summary
}

# Запуск основной функции
main "$@"
