#!/bin/bash
# ============================================================================
# Установка one_c_web_client_v3 с прокси на тестовый сервер
# cloud.smidt.keenetic.pro
# ============================================================================

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Установка one_c_web_client_v3 с прокси                 ║"
echo "║   cloud.smidt.keenetic.pro                               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    print_error "Запустите скрипт от root (sudo ./install_test.sh)"
    exit 1
fi

# Параметры
GITHUB_REPO="https://github.com/smidttmn/one_c_web_client.git"
GITHUB_BRANCH="feature/proxy-with-rewrite"
NC_PATH="/var/www/html/nextcloud"
APP_NAME="one_c_web_client_v3"

print_header "1. Проверка зависимостей..."

# Проверка git
if ! command -v git &>/dev/null; then
    print_error "git не установлен"
    exit 1
fi
print_success "git установлен"

# Проверка Nextcloud
if [ ! -f "$NC_PATH/occ" ]; then
    print_error "Nextcloud не найден: $NC_PATH"
    exit 1
fi
print_success "Nextcloud найден: $NC_PATH"

# Версия Nextcloud
NC_VERSION=$(sudo -u www-data php "$NC_PATH/occ" status --output=json 2>/dev/null | grep -o '"versionstring":"[^"]*"' | cut -d'"' -f4)
print_info "Версия Nextcloud: $NC_VERSION"

print_header "2. Клонирование репозитория..."

cd /tmp
rm -rf one_c_web_client
git clone -b "$GITHUB_BRANCH" "$GITHUB_REPO" one_c_web_client
print_success "Репозиторий склонирован"

print_header "3. Поиск приложения..."

# Ищем приложение в репозитории
APP_SOURCE=""
for path in "one_c_web_client_v3_clean" "one_c_web_client_v3" "app"; do
    if [ -d "/tmp/one_c_web_client/$path" ] && [ -f "/tmp/one_c_web_client/$path/appinfo/info.xml" ]; then
        APP_SOURCE="/tmp/one_c_web_client/$path"
        break
    fi
done

if [ -z "$APP_SOURCE" ]; then
    print_error "Приложение не найдено в репозитории"
    exit 1
fi

print_info "Приложение найдено: $APP_SOURCE"

print_header "4. Установка приложения..."

# Копируем приложение
cp -r "$APP_SOURCE" "$NC_PATH/apps/$APP_NAME"
chown -R www-data:www-data "$NC_PATH/apps/$APP_NAME"
chmod -R 755 "$NC_PATH/apps/$APP_NAME"
print_success "Приложение скопировано"

print_header "5. Включение приложения..."

if sudo -u www-data php "$NC_PATH/occ" app:install "$APP_NAME" 2>/dev/null; then
    print_success "Приложение установлено"
elif sudo -u www-data php "$NC_PATH/occ" app:enable "$APP_NAME" 2>/dev/null; then
    print_success "Приложение включено"
else
    print_error "Не удалось установить приложение"
    exit 1
fi

print_header "6. Очистка кэша..."

sudo -u www-data php "$NC_PATH/occ" maintenance:repair
sudo -u www-data php "$NC_PATH/occ" memcache:clear 2>/dev/null || true
print_success "Кэш очищен"

print_header "7. Проверка установки..."

if sudo -u www-data php "$NC_PATH/occ" app:list | grep -q "$APP_NAME"; then
    print_success "Приложение активно"
else
    print_error "Приложение не найдено"
    exit 1
fi

print_header "8. Проверка конфига Apache..."

# Проверяем, есть ли конфиг
APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
if [ ! -f "$APACHE_CONFIG" ]; then
    # Ищем другой конфиг
    for config in "/etc/apache2/sites-enabled/nextcloud.conf" "/etc/apache2/sites-available/000-default-le-ssl.conf"; do
        if [ -f "$config" ]; then
            APACHE_CONFIG="$config"
            break
        fi
    done
fi

if [ -f "$APACHE_CONFIG" ]; then
    print_info "Конфиг Apache: $APACHE_CONFIG"
    
    # Проверяем синтаксис
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_warning "Ошибка синтаксиса Apache"
    fi
else
    print_warning "Конфиг Apache не найден"
fi

print_header "9. Перезапуск Apache..."

if systemctl restart apache2; then
    print_success "Apache перезапущен"
else
    print_error "Не удалось перезапустить Apache"
fi

print_header "✅ Установка завершена!"

echo ""
echo "📋 Информация:"
echo ""
echo "  Приложение: $APP_NAME"
echo "  Nextcloud: $NC_PATH"
echo "  Ветка: $GITHUB_BRANCH"
echo ""
echo "📍 Откройте в браузере:"
echo ""
echo "  Админка Nextcloud:"
echo "    https://cloud.smidt.keenetic.pro/index.php/settings/admin"
echo ""
echo "  Настройки приложения:"
echo "    https://cloud.smidt.keenetic.pro/index.php/settings/admin/$APP_NAME"
echo ""
echo "  Клиентская часть:"
echo "    https://cloud.smidt.keenetic.pro/index.php/apps/$APP_NAME/"
echo ""
echo "🔧 Проверка:"
echo ""
echo "  sudo -u www-data php occ app:list | grep $APP_NAME"
echo "  tail -f /var/www/html/nextcloud/data/nextcloud.log"
echo ""
