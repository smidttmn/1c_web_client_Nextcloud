#!/bin/bash
# ============================================================================
# one_c_web_client_v3 - ПОЛНАЯ ОЧИСТКА ПЕРЕД УСТАНОВКОЙ
# Возвращает Nextcloud в исходное состояние
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ ОШИБКА: $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

if [ "$EUID" -ne 0 ]; then
    print_error "Запустите от root (sudo ./reset_nextcloud.sh)"
    exit 1
fi

print_info "═══════════════════════════════════════════════════════════"
print_info "ПОЛНАЯ ОЧИСТКА ПЕРЕД УСТАНОВКОЙ one_c_web_client_v3"
print_info "═══════════════════════════════════════════════════════════"
echo ""

# 1. Отключение и удаление приложения
print_step "1" "Отключение и удаление приложения"

NC_PATH="/var/www/nextcloud"
APP_NAME="one_c_web_client_v3"

if [ -d "$NC_PATH/apps/$APP_NAME" ]; then
    print_info "Отключение приложения..."
    sudo -u www-data php "$NC_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || true
    
    print_info "Удаление приложения..."
    sudo -u www-data php "$NC_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || true
    
    print_info "Удаление директории приложения..."
    rm -rf "$NC_PATH/apps/$APP_NAME"
    
    print_success "Приложение удалено"
else
    print_warning "Приложение не найдено"
fi

# 2. Очистка конфигурации приложения
print_step "2" "Очистка конфигурации приложения"

print_info "Удаление настроек приложения из config..."
sudo -u www-data php "$NC_PATH/occ" config:app:delete "$APP_NAME" 2>/dev/null || true
print_success "Конфигурация очищена"

# 3. Очистка кэша
print_step "3" "Очистка кэша"

print_info "Очистка кэша Nextcloud..."
sudo -u www-data php "$NC_PATH/occ" maintenance:repair
sudo -u www-data php "$NC_PATH/occ" maintenance:mode --off 2>/dev/null || true
print_success "Кэш очищен"

# 4. Восстановление Apache (если нужно)
print_step "4" "Проверка конфигурации Apache"

APACHE_CONFIG="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"

if [ -f "$APACHE_CONFIG" ]; then
    # Проверяем, есть ли наши настройки
    if grep -q "one_c_web_client_v3 - Прокси" "$APACHE_CONFIG" 2>/dev/null; then
        print_warning "Настройки прокси найдены"
        read -p "Удалить настройки прокси из Apache? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            mkdir -p "$BACKUP_DIR"
            cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
            print_success "Резервная копия: $BACKUP_DIR/apache_config.backup"
            
            # Удаляем настройки прокси
            sed -i '/# one_c_web_client_v3 - Прокси/,/# END one_c_web_client_v3/d' "$APACHE_CONFIG"
            print_success "Настройки прокси удалены"
            
            # Возвращаем AllowOverride All
            sed -i 's/AllowOverride None/AllowOverride All/g' "$APACHE_CONFIG"
            print_success "AllowOverride восстановлен"
            
            # Проверка синтаксиса
            print_info "Проверка синтаксиса Apache..."
            if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
                print_success "Синтаксис корректен"
                print_info "Перезапуск Apache..."
                systemctl restart apache2
                print_success "Apache перезапущен"
            else
                print_error "Ошибка синтаксиса Apache!"
                print_info "Восстановление резервной копии..."
                cp "$BACKUP_DIR/apache_config.backup" "$APACHE_CONFIG"
            fi
        else
            print_info "Настройки прокси сохранены"
        fi
    else
        print_success "Настройки прокси не найдены (Apache чист)"
    fi
else
    print_warning "Конфигурация Apache не найдена"
fi

# 5. Итог
print_header "ГОТОВО!"

echo ""
echo "📋 Nextcloud очищен и готов к установке!"
echo ""
echo "  Приложение:  Удалено"
echo "  Конфигурация: Очищена"
echo "  Кэш: Очищен"
if [ -f "$BACKUP_DIR/apache_config.backup" ]; then
    echo "  Apache: Очищен (резервная копия: $BACKUP_DIR/apache_config.backup)"
else
    echo "  Apache: Без изменений"
fi
echo ""
echo "📋 Следующий шаг:"
echo ""
echo "  Запустите установку:"
echo "  sudo /path/to/install_package/install.sh"
echo ""
echo "  или"
echo ""
echo "  cd /home/smidt/nc1c"
echo "  sudo ./install_package/install.sh"
echo ""

print_success "Очистка завершена!"
