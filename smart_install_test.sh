#!/bin/bash
# ============================================================================
# УМНЫЙ УСТАНОВЩИК one_c_web_client_v3 для cloud.smidt.keenetic.pro
# Версия: 1.0.0 - С полным логированием и диагностикой
# ============================================================================
# 
# Этот скрипт:
# - Устанавливает приложение с прокси
# - Логирует все шаги
# - Проверяет каждую операцию
# - Не ломает существующие настройки
# - При ошибке - откатывает изменения
# ============================================================================

set -e

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

# Функции вывода
print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   $1"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() { echo -e "${YELLOW}[ШАГ $1] $2${NC}"; }
print_success() { echo -e "${GREEN}  ✓ $1${NC}"; }
print_error() { echo -e "${RED}  ✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${CYAN}  ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}  ⚠ $1${NC}"; }

# Откат изменений
rollback() {
    print_error "Произошла ошибка! Выполняю откат..."
    
    # Удаляем приложение
    if [ -n "$APP_NAME" ] && [ -n "$NC_PATH" ]; then
        sudo -u www-data php "$NC_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || true
        sudo -u www-data php "$NC_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || true
        rm -rf "$NC_PATH/apps/$APP_NAME" 2>/dev/null || true
        print_success "Приложение удалено"
    fi
    
    # Восстанавливаем конфиг Apache если есть резервная копия
    if [ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/apache_config.backup" ]; then
        cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
        systemctl restart apache2
        print_success "Конфиг Apache восстановлен"
    fi
    
    print_info "Лог установки: $LOG_FILE"
    print_info "Отправьте этот лог разработчику для анализа"
    exit 1
}

trap rollback ERR

# ============================================================================
# ОСНОВНАЯ ЧАСТЬ
# ============================================================================

print_header "Умный установщик one_c_web_client_v3"

echo "Сервер: $(hostname)"
echo "Дата: $(date)"
echo "Лог: $LOG_FILE"
echo ""

# Параметры
GITHUB_REPO="https://github.com/smidttmn/one_c_web_client.git"
GITHUB_BRANCH="feature/proxy-with-rewrite"
NC_PATH="/var/www/html/nextcloud"
APP_NAME="one_c_web_client_v3"
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"

# Проверка прав
print_step "0" "Проверка прав доступа"
if [ "$EUID" -ne 0 ]; then
    print_error "Запустите скрипт от имени пользователя с sudo"
    exit 1
fi
print_success "Права подтверждены"

# Проверка Nextcloud
print_step "1" "Проверка Nextcloud"
if [ ! -f "$NC_PATH/occ" ]; then
    print_error "Nextcloud не найден: $NC_PATH"
    exit 1
fi
print_success "Nextcloud найден: $NC_PATH"

# Версия Nextcloud
NC_VERSION=$(sudo -u www-data php "$NC_PATH/occ" status --output=json 2>/dev/null | grep -o '"versionstring":"[^"]*"' | cut -d'"' -f4)
print_info "Версия Nextcloud: $NC_VERSION"

# Проверка Apache
print_step "2" "Проверка Apache"
APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
if [ ! -f "$APACHE_CONFIG" ]; then
    # Ищем другой конфиг
    for config in "/etc/apache2/sites-enabled/nextcloud.conf" "/etc/apache2/sites-available/000-default-le-ssl.conf" "/etc/apache2/sites-enabled/000-default-le-ssl.conf"; do
        if [ -f "$config" ]; then
            APACHE_CONFIG="$config"
            break
        fi
    done
fi

if [ -f "$APACHE_CONFIG" ]; then
    print_info "Конфиг Apache: $APACHE_CONFIG"
    
    # Создаём резервную копию
    mkdir -p "$BACKUP_DIR"
    cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
    print_success "Резервная копия создана: $BACKUP_DIR/apache_config.backup"
    
    # Проверяем синтаксис
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        print_success "Синтаксис Apache корректен"
    else
        print_warning "Ошибка синтаксиса Apache"
    fi
else
    print_warning "Конфиг Apache не найден (возможно используется другой)"
fi

# Проверка модулей Apache
print_step "3" "Проверка модулей Apache"
REQUIRED_MODULES=("proxy" "proxy_http" "proxy_wstunnel" "headers" "rewrite" "ssl")
MISSING_MODULES=()

for module in "${REQUIRED_MODULES[@]}"; do
    if a2query -m "$module" 2>/dev/null; then
        print_success "  Модуль $module: включён"
    else
        MISSING_MODULES+=("$module")
        print_warning "  Модуль $module: отключён"
    fi
done

if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    print_info "Включение отсутствующих модулей..."
    for module in "${MISSING_MODULES[@]}"; do
        a2enmod "$module" 2>/dev/null && print_success "Модуль $module включён"
    done
fi

# Клонируем репозиторий
print_step "4" "Клонирование репозитория"
cd /tmp
rm -rf one_c_web_client
git clone -b "$GITHUB_BRANCH" "$GITHUB_REPO" one_c_web_client 2>&1 | tee -a "$LOG_FILE"
print_success "Репозиторий склонирован"

# Поиск приложения
print_step "5" "Поиск приложения"
APP_SOURCE=""
for path in "one_c_web_client_v3_clean" "one_c_web_client_v3" "app/one_c_web_client_v3" "clean_app"; do
    if [ -d "/tmp/one_c_web_client/$path" ] && [ -f "/tmp/one_c_web_client/$path/appinfo/info.xml" ]; then
        APP_SOURCE="/tmp/one_c_web_client/$path"
        break
    fi
done

if [ -z "$APP_SOURCE" ]; then
    print_error "Приложение не найдено в репозитории"
    ls -la /tmp/one_c_web_client/
    exit 1
fi

print_info "Приложение найдено: $APP_SOURCE"

# Проверка содержимого приложения
print_step "6" "Проверка содержимого приложения"
REQUIRED_FILES=("appinfo/info.xml" "lib/AppInfo/Application.php" "templates/index.php")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$APP_SOURCE/$file" ]; then
        print_success "  $file: найден"
    else
        print_error "  $file: не найден"
        exit 1
    fi
done

# Проверка на наличие ProxyController
if [ -f "$APP_SOURCE/lib/Controller/ProxyController.php" ]; then
    print_success "  ProxyController: найден (приложение с прокси)"
else
    print_warning "  ProxyController: не найден (приложение без прокси)"
fi

# Установка приложения
print_step "7" "Установка приложения"

# Проверяем, не установлено ли уже
if sudo -u www-data php "$NC_PATH/occ" app:list 2>/dev/null | grep -q "$APP_NAME"; then
    print_warning "Приложение уже установлено"
    read -p "Удалить старую версию и установить заново? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        print_info "Удаление старой версии..."
        sudo -u www-data php "$NC_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || true
        sudo -u www-data php "$NC_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || true
        rm -rf "$NC_PATH/apps/$APP_NAME" 2>/dev/null || true
        print_success "Старая версия удалена"
    else
        print_info "Установка отменена"
        exit 0
    fi
fi

# Копируем приложение
cp -r "$APP_SOURCE" "$NC_PATH/apps/$APP_NAME"
chown -R www-data:www-data "$NC_PATH/apps/$APP_NAME"
chmod -R 755 "$NC_PATH/apps/$APP_NAME"
print_success "Приложение скопировано"

# Включаем приложение
print_step "8" "Включение приложения"
if sudo -u www-data php "$NC_PATH/occ" app:install "$APP_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    print_success "Приложение установлено"
elif sudo -u www-data php "$NC_PATH/occ" app:enable "$APP_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    print_success "Приложение включено"
else
    print_error "Не удалось установить приложение"
    exit 1
fi

# Очистка кэша
print_step "9" "Очистка кэша"
sudo -u www-data php "$NC_PATH/occ" maintenance:repair 2>&1 | tee -a "$LOG_FILE"
sudo -u www-data php "$NC_PATH/occ" memcache:clear 2>/dev/null || true
print_success "Кэш очищен"

# Перезапуск Apache
print_step "10" "Перезапуск Apache"
if systemctl restart apache2 2>&1 | tee -a "$LOG_FILE"; then
    print_success "Apache перезапущен"
else
    print_warning "Не удалось перезапустить Apache"
fi

# Проверка установки
print_step "11" "Проверка установки"
if sudo -u www-data php "$NC_PATH/occ" app:list 2>&1 | grep -q "$APP_NAME"; then
    print_success "Приложение активно"
else
    print_error "Приложение не найдено"
    exit 1
fi

# Проверка логов на ошибки
print_step "12" "Проверка логов"
ERROR_COUNT=$(sudo -u www-data php "$NC_PATH/occ" log:read 2>/dev/null | grep -c "one_c_web_client_v3.*Exception" || echo "0")
if [ "$ERROR_COUNT" -gt 0 ]; then
    print_warning "Найдено ошибок в логах: $ERROR_COUNT"
    print_info "Проверьте логи: sudo -u www-data php occ log:read"
else
    print_success "Ошибок в логах не найдено"
fi

# Финальный отчёт
print_header "Установка завершена!"

echo ""
echo "📋 Информация:"
echo ""
echo "  Приложение: $APP_NAME"
echo "  Nextcloud: $NC_PATH"
echo "  Ветка: $GITHUB_BRANCH"
echo "  Лог: $LOG_FILE"
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
echo "📞 Если что-то не работает:"
echo ""
echo "  Отправьте разработчику файл лога: $LOG_FILE"
echo ""
