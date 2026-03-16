#!/bin/bash
# ============================================================================
# Автоматическая установка one_c_web_client_v3 на cloud.smidt.keenetic.pro
# Запуск через SSH с автоматическим вводом пароля
# ============================================================================

set -e

SUDO_PASS="Apple0589"
NC_PATH="/var/www/nextcloud"
APP_NAME="one_c_web_client_v3"
GITHUB_BRANCH="feature/proxy-with-rewrite"
LOG_FILE="/tmp/one_c_auto_install_$(date +%Y%m%d_%H%M%S).log"

# Функции
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

run_sudo() {
    echo "$SUDO_PASS" | sudo -S "$@" 2>&1 | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ ОШИБКА: $1"
    log "📋 Лог: $LOG_FILE"
    exit 1
}

# Начало
log "🚀 Начало установки"
log "📝 Лог: $LOG_FILE"

# Проверка Nextcloud
log "📋 Проверка Nextcloud..."
if [ ! -f "$NC_PATH/occ" ]; then
    error_exit "Nextcloud не найден: $NC_PATH"
fi
log "✅ Nextcloud найден"

# Версия Nextcloud
NC_VER=$(run_sudo sh -c "php $NC_PATH/occ status --output=json | grep -o '\"versionstring\":\"[^\"]*\"' | cut -d'\"' -f4")
log "ℹ️ Версия Nextcloud: $NC_VER"

# Проверка Apache
log "📋 Проверка Apache..."
APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
if [ ! -f "$APACHE_CONFIG" ]; then
    APACHE_CONFIG="/etc/apache2/sites-enabled/000-default-le-ssl.conf"
fi
log "ℹ️ Конфиг Apache: $APACHE_CONFIG"

# Резервная копия
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
if [ -f "$APACHE_CONFIG" ]; then
    cp "$APACHE_CONFIG" "$BACKUP_DIR/apache_config.backup"
    log "💾 Резервная копия: $BACKUP_DIR/apache_config.backup"
fi

# Проверка модулей Apache
log "📋 Проверка модулей Apache..."
for module in proxy proxy_http proxy_wstunnel headers rewrite ssl; do
    if run_sudo a2query -m "$module" >/dev/null 2>&1; then
        log "✅ Модуль $module: включён"
    else
        log "⚠️ Модуль $module: отключён (будет включён)"
        run_sudo a2enmod "$module" || true
    fi
done

# Клонируем репозиторий
log "📦 Клонирование репозитория..."
cd /tmp
rm -rf one_c_web_client
git clone -b "$GITHUB_BRANCH" https://github.com/smidttmn/one_c_web_client.git one_c_web_client 2>&1 | tee -a "$LOG_FILE"
log "✅ Репозиторий склонирован"

# Поиск приложения
log "🔍 Поиск приложения..."
APP_SOURCE=""
for path in "one_c_web_client_v3_clean" "one_c_web_client_v3" "app/one_c_web_client_v3"; do
    if [ -d "/tmp/one_c_web_client/$path" ] && [ -f "/tmp/one_c_web_client/$path/appinfo/info.xml" ]; then
        APP_SOURCE="/tmp/one_c_web_client/$path"
        break
    fi
done

if [ -z "$APP_SOURCE" ]; then
    error_exit "Приложение не найдено!"
fi
log "✅ Приложение найдено: $APP_SOURCE"

# Проверка ProxyController
if [ -f "$APP_SOURCE/lib/Controller/ProxyController.php" ]; then
    log "✅ ProxyController: найден (приложение с прокси)"
else
    log "⚠️ ProxyController: не найден"
fi

# Удаляем старую версию
log "🗑️ Проверка старой версии..."
if run_sudo sh -c "php $NC_PATH/occ app:list 2>/dev/null" | grep -q "$APP_NAME"; then
    log "⚠️ Приложение уже установлено, удаляю..."
    run_sudo sh -c "php $NC_PATH/occ app:disable $APP_NAME" || true
    run_sudo sh -c "php $NC_PATH/occ app:remove $APP_NAME" || true
    run_sudo rm -rf "$NC_PATH/apps/$APP_NAME" || true
    log "✅ Старая версия удалена"
fi

# Установка приложения
log "📦 Установка приложения..."
run_sudo cp -r "$APP_SOURCE" "$NC_PATH/apps/$APP_NAME" || error_exit "Не удалось скопировать приложение"
run_sudo chown -R www-data:www-data "$NC_PATH/apps/$APP_NAME"
run_sudo chmod -R 755 "$NC_PATH/apps/$APP_NAME"
log "✅ Приложение скопировано"

# Включение приложения
log "🔧 Включение приложения..."
if run_sudo sh -c "php $NC_PATH/occ app:install $APP_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    log "✅ Приложение установлено"
else
    error_exit "Не удалось установить приложение"
fi

# Очистка кэша
log "🧹 Очистка кэша..."
run_sudo sh -c "php $NC_PATH/occ maintenance:repair" 2>&1 | tee -a "$LOG_FILE" || true
# memcache:clear может не существовать в некоторых версиях Nextcloud
run_sudo sh -c "php $NC_PATH/occ memcache:clear 2>/dev/null || php $NC_PATH/occ maintenance:repair" 2>&1 | tee -a "$LOG_FILE" || true
log "✅ Кэш очищен"

# Перезапуск Apache
log "🔄 Перезапуск Apache..."
run_sudo systemctl restart apache2 || error_exit "Не удалось перезапустить Apache"
log "✅ Apache перезапущен"

# Проверка установки
log "✅ Проверка установки..."
if run_sudo sh -c "php $NC_PATH/occ app:list" | grep -q "$APP_NAME"; then
    log "✅ Приложение активно"
else
    error_exit "Приложение не найдено"
fi

# Проверка логов
log "📊 Проверка логов..."
ERROR_COUNT=$(run_sudo sh -c "php $NC_PATH/occ log:read 2>/dev/null" | grep -c "one_c_web_client_v3.*Exception" 2>/dev/null || echo "0")
if [ "$ERROR_COUNT" != "0" ] && [ "$ERROR_COUNT" -gt 0 ] 2>/dev/null; then
    log "⚠️ Найдено ошибок в логах: $ERROR_COUNT"
else
    log "✅ Ошибок в логах не найдено"
fi

# Финальный отчёт
log "╔═══════════════════════════════════════════════════════════╗"
log "║   ✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!                        ║"
log "╚═══════════════════════════════════════════════════════════╝"
log ""
log "📍 Откройте в браузере:"
log "   https://cloud.smidt.keenetic.pro/index.php/apps/$APP_NAME/"
log ""
log "📋 Лог установки: $LOG_FILE"
log ""

exit 0
