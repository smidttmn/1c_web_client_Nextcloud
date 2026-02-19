#!/bin/bash
# ============================================================================
# Скрипт для создания установочного архива one_c_web_client
# ============================================================================

set -e

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Создание установочного архива one_c_web_client${NC}"
echo ""

# Переходим в директорию проекта
cd /home/smidt/nc1c

# Создаем временную директорию для сборки
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}Сборка в директории: $TEMP_DIR${NC}"

# Создаем директорию приложения
mkdir -p "$TEMP_DIR/one_c_web_client"

# Копируем файлы приложения
echo "Копирование файлов приложения..."
cp -r appinfo lib templates js css img l10n "$TEMP_DIR/one_c_web_client/"

# Копируем обязательные файлы
cp LICENSE "$TEMP_DIR/one_c_web_client/" 2>/dev/null || echo "LICENSE не найден"

# Копируем документацию для архива
echo "Копирование документации..."
cp ARCHIVE_README.md "$TEMP_DIR/one_c_web_client/README.md"
cp QUICK_START_RU.md "$TEMP_DIR/one_c_web_client/"
cp INSTALLATION_GUIDE.md "$TEMP_DIR/one_c_web_client/"

# Копируем скрипт установки
echo "Копирование скрипта установки..."
cp deploy.sh "$TEMP_DIR/"
chmod +x "$TEMP_DIR/deploy.sh"

# Создаем архив
echo "Создание архива..."
cd "$TEMP_DIR"
tar -czf /home/smidt/one_c_web_client_deploy.tar.gz one_c_web_client deploy.sh

# Очищаем временную директорию
echo "Очистка..."
rm -rf "$TEMP_DIR"

# Показываем результат
echo ""
echo -e "${GREEN}✓ Архив успешно создан!${NC}"
echo ""
echo "Путь: /home/smidt/one_c_web_client_deploy.tar.gz"
echo "Размер:"
ls -lh /home/smidt/one_c_web_client_deploy.tar.gz | awk '{print $5}'
echo ""
echo -e "${BLUE}Содержимое архива:${NC}"
tar -tzf /home/smidt/one_c_web_client_deploy.tar.gz | head -20
echo "..."
echo ""
echo -e "${YELLOW}Готово к развертыванию!${NC}"
