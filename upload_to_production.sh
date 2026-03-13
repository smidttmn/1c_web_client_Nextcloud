#!/bin/bash
# ============================================================================
# Скрипт для отправки файлов на продакшн-сервер
# drive.technoorganic.info / drive.nppsgt.com
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Проверяем файлы
print_info "Проверка файлов..."

FILES=(
    "install_production.sh"
    "INSTALL_PRODUCTION.md"
    "one_c_web_client_v3_deploy.tar.gz"
)

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Файл не найден: $file"
        exit 1
    fi
    print_success "Файл найден: $file"
done

# Копируем на сервер
SERVER="root@drive.technoorganic.info"
REMOTE_DIR="/tmp"

echo ""
print_info "Копирование на сервер: $SERVER:$REMOTE_DIR"
echo ""

# Копируем файлы
scp install_production.sh $SERVER:$REMOTE_DIR/
scp INSTALL_PRODUCTION.md $SERVER:$REMOTE_DIR/
scp one_c_web_client_v3_deploy.tar.gz $SERVER:$REMOTE_DIR/

echo ""
print_success "Файлы скопированы!"
echo ""
print_info "Следующие шаги:"
echo ""
echo "1. Подключитесь к серверу:"
echo "   ssh $SERVER"
echo ""
echo "2. Перейдите в директорию:"
echo "   cd $REMOTE_DIR"
echo ""
echo "3. Запустите установку:"
echo "   chmod +x install_production.sh"
echo "   ./install_production.sh"
echo ""
print_success "Готово!"
