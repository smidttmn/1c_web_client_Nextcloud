#!/bin/bash

###############################################################################
# one_c_web_client_v3 - Автоматический установщик
# Интеграция 1С:Предприятие с Nextcloud
# Версия: 3.0.0
# Дата: Март 2026
###############################################################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Без цвета

# Переменные
APP_NAME="one_c_web_client_v3"
APP_DIR="/var/www/nextcloud/apps/one_c_web_client_v3"
NEXTCLOUD_PATH="/var/www/nextcloud"
APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
ONE_C_SERVER="${ONE_C_SERVER:-https://10.72.1.5}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   one_c_web_client_v3 - Установка интеграции 1С           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ошибка: Запустите скрипт от root${NC}"
    exit 1
fi

# Проверка существования Nextcloud
if [ ! -d "$NEXTCLOUD_PATH" ]; then
    echo -e "${RED}Ошибка: Nextcloud не найден в $NEXTCLOUD_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Nextcloud найден${NC}"

###############################################################################
# Шаг 1: Копирование файлов приложения
###############################################################################
echo -e "${YELLOW}[1/5] Копирование файлов приложения...${NC}"

# Создаём директорию приложения
mkdir -p "$APP_DIR"/{appinfo,lib/Controller,lib/Settings,templates,js,css,img,l10n}

# Копируем файлы (предполагается, что скрипт запущен из директории с файлами)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/app" ]; then
    cp -r "$SCRIPT_DIR/app/"* "$APP_DIR/"
    echo -e "${GREEN}✓ Файлы приложения скопированы${NC}"
else
    echo -e "${RED}Ошибка: Директория app/ не найдена в $SCRIPT_DIR${NC}"
    exit 1
fi

# Установка правильных прав
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"
echo -e "${GREEN}✓ Права установлены${NC}"

###############################################################################
# Шаг 2: Настройка Apache
###############################################################################
echo -e "${YELLOW}[2/5] Настройка Apache...${NC}"

# Создаём резервную копию конфига
if [ -f "$APACHE_CONFIG" ]; then
    cp "$APACHE_CONFIG" "${APACHE_CONFIG}.bak.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Резервная копия конфига создана${NC}"
fi

# Копируем новый конфиг
if [ -f "$SCRIPT_DIR/apache_nextcloud.conf" ]; then
    cp "$SCRIPT_DIR/apache_nextcloud.conf" "$APACHE_CONFIG"
    echo -e "${GREEN}✓ Конфиг Apache обновлён${NC}"
else
    echo -e "${YELLOW}⚠ Файл apache_nextcloud.conf не найден, пропускаем${NC}"
fi

# Включаем необходимые модули Apache
a2enmod proxy proxy_http rewrite headers ssl 2>/dev/null || true
echo -e "${GREEN}✓ Модули Apache включены${NC}"

###############################################################################
# Шаг 3: Установка приложения в Nextcloud
###############################################################################
echo -e "${YELLOW}[3/5] Установка приложения в Nextcloud...${NC}"

# Отключаем старую версию если есть
sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable one_c_web_client_v2 2>/dev/null || true
sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable one_c_web_client 2>/dev/null || true

# Устанавливаем новую версию
sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:install "$APP_NAME" 2>/dev/null || \
sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:enable "$APP_NAME"

echo -e "${GREEN}✓ Приложение установлено${NC}"

###############################################################################
# Шаг 4: Очистка кэша
###############################################################################
echo -e "${YELLOW}[4/5] Очистка кэша...${NC}"

sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:repair
sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:mode --off 2>/dev/null || true

# Перезагрузка Apache
systemctl reload apache2
echo -e "${GREEN}✓ Кэш очищен, Apache перезапущен${NC}"

###############################################################################
# Шаг 5: Проверка установки
###############################################################################
echo -e "${YELLOW}[5/5] Проверка установки...${NC}"

# Проверяем, включено ли приложение
if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:list | grep -q "$APP_NAME"; then
    echo -e "${GREEN}✓ Приложение активно${NC}"
else
    echo -e "${RED}⚠ Приложение не найдено в списке активных${NC}"
fi

# Проверяем конфиг Apache
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    echo -e "${GREEN}✓ Конфигурация Apache корректна${NC}"
else
    echo -e "${RED}⚠ Ошибка в конфигурации Apache${NC}"
fi

###############################################################################
# Завершение
###############################################################################
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Установка завершена успешно!                            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Следующие шаги:${NC}"
echo ""
echo "1. Откройте админ-панель Nextcloud"
echo "   https://your-nextcloud-domain/index.php/settings/admin/one_c_web_client_v3"
echo ""
echo "2. Добавьте базы 1С через интерфейс"
echo "   - Название: Бухгалтерия"
echo "   - Идентификатор: buh (должен совпадать с путём в 1С)"
echo "   - URL: $ONE_C_SERVER/buh"
echo ""
echo "3. Проверьте работу приложения"
echo "   https://your-nextcloud-domain/index.php/apps/one_c_web_client_v3/onec"
echo ""
echo "4. Проверьте защиту (режим инкогнито)"
echo "   https://your-nextcloud-domain/buh/ → должен быть редирект на login"
echo ""
echo -e "${YELLOW}📖 Полная документация в файле README.md${NC}"
echo ""
