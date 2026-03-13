#!/bin/bash
# ============================================================================
# Скрипт полной переустановки one_c_web_client_v3 с очисткой кэша
# ============================================================================

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Полная переустановка one_c_web_client_v3               ║"
echo "║   с очисткой кэша PHP OPcache                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

NC_PATH="/var/www/html/nextcloud"
APP_NAME="one_c_web_client_v3"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    print_error "Запустите от root (sudo ./full_reinstall.sh)"
    exit 1
fi

echo "[1/10] Отключение приложения..."
sudo -u www-data php "$NC_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || print_info "Приложение не было включено"

echo "[2/10] Удаление приложения..."
sudo -u www-data php "$NC_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || print_info "Приложение не было установлено"

echo "[3/10] Удаление файлов приложения..."
rm -rf "$NC_PATH/apps/$APP_NAME"
print_success "Файлы удалены"

echo "[4/10] Очистка кэша Nextcloud..."
sudo -u www-data php "$NC_PATH/occ" maintenance:repair
sudo -u www-data php "$NC_PATH/occ" memcache:clear 2>/dev/null || true
print_success "Кэш Nextcloud очищен"

echo "[5/10] Очистка кэша PHP OPcache..."
# Перезапуск PHP-FPM для очистки OPcache
if systemctl is-active --quiet php8.1-fpm; then
    systemctl restart php8.1-fpm
    print_success "PHP-FPM перезапущен"
elif systemctl is-active --quiet php80-fpm; then
    systemctl restart php80-fpm
    print_success "PHP80-FPM перезапущен"
elif systemctl is-active --quiet php-fpm; then
    systemctl restart php-fpm
    print_success "PHP-FPM перезапущен"
else
    print_info "PHP-FPM не найден, пробуем очистить через CLI"
    echo "<?php if(function_exists('opcache_reset')) opcache_reset(); ?>" | php
    print_success "OPcache очищен через CLI"
fi

echo "[6/10] Распаковка новой версии приложения..."
cd "$NC_PATH/apps"

# Ищем архив
ARCHIVE=""
for path in "/tmp/one_c_web_client_v3_fixed.tar.gz" "/home/smidt/one_c_web_client_v3_fixed.tar.gz"; do
    if [ -f "$path" ]; then
        ARCHIVE="$path"
        break
    fi
done

if [ -z "$ARCHIVE" ]; then
    print_error "Архив не найден!"
    print_info "Скопируйте one_c_web_client_v3_fixed.tar.gz в /tmp/"
    exit 1
fi

print_info "Архив: $ARCHIVE"
tar -xzf "$ARCHIVE"
mv one_c_web_client_v3_clean "$APP_NAME"
print_success "Приложение распаковано"

echo "[7/10] Установка прав..."
chown -R www-data:www-data "$NC_PATH/apps/$APP_NAME"
chmod -R 755 "$NC_PATH/apps/$APP_NAME"
print_success "Права установлены"

echo "[8/10] Проверка Application.php..."
APP_FILE="$NC_PATH/apps/$APP_NAME/lib/AppInfo/Application.php"
if grep -q "registerAdminSettings" "$APP_FILE"; then
    print_error "НАЙДЕН СТАРЫЙ КОД! Архив не обновлён!"
    print_info "В файле найден вызов registerAdminSettings()"
    exit 1
else
    print_success "Application.php содержит правильный код"
fi

echo "[9/10] Установка приложения..."
if sudo -u www-data php "$NC_PATH/occ" app:install "$APP_NAME"; then
    print_success "Приложение установлено"
else
    print_error "Не удалось установить приложение"
    exit 1
fi

echo "[10/10] Очистка кэша и перезапуск Apache..."
sudo -u www-data php "$NC_PATH/occ" maintenance:repair
sudo -u www-data php "$NC_PATH/occ" memcache:clear 2>/dev/null || true

if systemctl restart apache2; then
    print_success "Apache перезапущен"
else
    print_error "Не удалось перезапустить Apache"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   ✅ Переустановка завершена успешно!                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
print_info "Проверьте работу Nextcloud:"
echo "  https://drive.nppsgt.com/index.php/settings/admin"
echo ""
print_info "Проверьте логи:"
echo "  sudo -u www-data php occ log:read | tail -20"
echo ""
