#!/bin/bash
# nc1c - Автоматический скрипт установки
# Версия: 1.0.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}nc1c - Установка приложения${NC}"
echo -e "${GREEN}Версия: 1.0.0${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ошибка: Запустите от root (sudo)${NC}"
    exit 1
fi

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_APPS_DIR="/var/www/nextcloud/apps"
NC_OCC="sudo -u www-data php /var/www/nextcloud/occ"

# Проверка существования Nextcloud
if [ ! -d "/var/www/nextcloud" ]; then
    echo -e "${RED}Ошибка: Nextcloud не найден в /var/www/nextcloud${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/6] Проверка структуры приложения...${NC}"
if [ ! -d "$SCRIPT_DIR/appinfo" ] || [ ! -d "$SCRIPT_DIR/lib" ]; then
    echo -e "${RED}Ошибка: Неправильная структура приложения${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Структура верна${NC}"
echo ""

echo -e "${YELLOW}[2/6] Копирование в apps Nextcloud...${NC}"
if [ -d "$NC_APPS_DIR/nc1c" ]; then
    echo -e "${YELLOW}Предупреждение: nc1c уже существует, удаляем...${NC}"
    rm -rf "$NC_APPS_DIR/nc1c"
fi
cp -r "$SCRIPT_DIR" "$NC_APPS_DIR/nc1c"
echo -e "${GREEN}✓ Скопировано в $NC_APPS_DIR/nc1c${NC}"
echo ""

echo -e "${YELLOW}[3/6] Установка прав...${NC}"
chown -R www-data:www-data "$NC_APPS_DIR/nc1c"
chmod -R 755 "$NC_APPS_DIR/nc1c"
echo -e "${GREEN}✓ Права установлены${NC}"
echo ""

echo -e "${YELLOW}[4/6] Установка приложения через OCC...${NC}"
$NC_OCC app:install nc1c || {
    echo -e "${YELLOW}Приложение уже установлено, обновляем...${NC}"
    $NC_OCC app:enable nc1c
}
echo -e "${GREEN}✓ Приложение установлено${NC}"
echo ""

echo -e "${YELLOW}[5/6] Очистка кэша...${NC}"
$NC_OCC maintenance:repair
echo -e "${GREEN}✓ Кэш очищен${NC}"
echo ""

echo -e "${YELLOW}[6/6] Проверка статуса...${NC}"
if $NC_OCC app:list | grep -q "nc1c"; then
    echo -e "${GREEN}✓ nc1c успешно установлено и включено!${NC}"
else
    echo -e "${RED}Ошибка: Приложение не найдено${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Установка завершена!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Откройте Nextcloud в браузере"
echo "2. Настройки → Администрирование → 1C WebClient"
echo "3. Добавьте базы 1С (URL должен быть HTTPS!)"
echo ""
echo -e "${YELLOW}Пример:${NC}"
echo "  Название: Бухгалтерия"
echo "  URL: https://10.72.1.5/sgtbuh/"
echo ""
echo -e "${GREEN}Готово!${NC}"
