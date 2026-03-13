#!/bin/bash
# ============================================================================
# Скрипт для установки ИСПРАВЛЕННОЙ версии one_c_web_client_v3
# Версия 3.2.2 - Исправлена ошибка 500
# ============================================================================

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Установка исправленной версии one_c_web_client_v3      ║"
echo "║   Версия 3.2.2 - Исправлена ошибка 500                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ошибка: Запустите скрипт от root (sudo ./install_fixed.sh)"
    exit 1
fi

NC_PATH="/var/www/html/nextcloud"
APP_NAME="one_c_web_client_v3"
FIXED_ARCHIVE="/tmp/one_c_web_client_v3_fixed.tar.gz"

# Проверка существования архива
if [ ! -f "$FIXED_ARCHIVE" ]; then
    echo "❌ Ошибка: Архив не найден: $FIXED_ARCHIVE"
    echo "ℹ️ Скопируйте файл one_c_web_client_v3_fixed.tar.gz в /tmp/"
    exit 1
fi

echo "✅ Архив найден: $FIXED_ARCHIVE"
echo ""

# Шаг 1: Отключаем старую версию
echo "📦 Шаг 1: Отключение старой версии..."
sudo -u www-data php "$NC_PATH/occ" app:disable "$APP_NAME" 2>/dev/null || echo "   Приложение не было включено"

# Шаг 2: Удаляем старую версию
echo "📦 Шаг 2: Удаление старой версии..."
sudo -u www-data php "$NC_PATH/occ" app:remove "$APP_NAME" 2>/dev/null || echo "   Приложение не было установлено"

# Шаг 3: Удаляем файлы приложения
echo "📦 Шаг 3: Удаление файлов приложения..."
rm -rf "$NC_PATH/apps/$APP_NAME"
echo "   ✅ Файлы удалены"

# Шаг 4: Очищаем кэш
echo "🧹 Шаг 4: Очистка кэша..."
sudo -u www-data php "$NC_PATH/occ" maintenance:repair
sudo -u www-data php "$NC_PATH/occ" memcache:clear 2>/dev/null || echo "   Команда memcache:clear недоступна"
echo "   ✅ Кэш очищен"

# Шаг 5: Распаковываем исправленную версию
echo "📦 Шаг 5: Распаковка исправленной версии..."
cd "$NC_PATH/apps"
tar -xzf "$FIXED_ARCHIVE"
mv one_c_web_client_v3_clean "$APP_NAME"
echo "   ✅ Файлы распакованы"

# Шаг 6: Устанавливаем права
echo "🔐 Шаг 6: Установка прав..."
chown -R www-data:www-data "$NC_PATH/apps/$APP_NAME"
chmod -R 755 "$NC_PATH/apps/$APP_NAME"
echo "   ✅ Права установлены"

# Шаг 7: Устанавливаем приложение
echo "📦 Шаг 7: Установка приложения..."
if sudo -u www-data php "$NC_PATH/occ" app:install "$APP_NAME"; then
    echo "   ✅ Приложение установлено"
else
    echo "   ❌ Ошибка установки приложения"
    exit 1
fi

# Шаг 8: Очищаем кэш ещё раз
echo "🧹 Шаг 8: Повторная очистка кэша..."
sudo -u www-data php "$NC_PATH/occ" maintenance:repair
sudo -u www-data php "$NC_PATH/occ" memcache:clear 2>/dev/null || echo "   Команда memcache:clear недоступна"
echo "   ✅ Кэш очищен"

# Шаг 9: Перезапускаем Apache
echo "🔄 Шаг 9: Перезапуск Apache..."
systemctl restart apache2
echo "   ✅ Apache перезапущен"

# Итог
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   ✅ Установка завершена успешно!                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Проверка:"
echo ""
echo "1. Откройте в браузере:"
echo "   https://drive.nppsgt.com/index.php/settings/admin"
echo ""
echo "2. Откройте настройки приложения:"
echo "   https://drive.nppsgt.com/index.php/settings/admin/$APP_NAME"
echo ""
echo "3. Проверьте статус приложения:"
echo "   sudo -u www-data php occ app:list | grep $APP_NAME"
echo ""
echo "✅ Готово!"
