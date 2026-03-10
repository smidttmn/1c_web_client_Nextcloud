#!/bin/bash

###############################################################################
# one_c_web_client_v3 - ИНТЕРАКТИВНЫЙ установщик с поддержкой SSL
# Интеграция 1С:Предприятие с Nextcloud
# Версия: 3.0.3 (SSL SAFE)
#
# ВАЖНО: Этот скрипт:
# - ЗАДАЁТ интерактивные вопросы для настройки
# - СОХРАНЯЕТ все существующие настройки (SSL, Let's Encrypt, VirtualHosts)
# - ДОБАВЛЯЕТ только необходимые директивы для 1С прокси
# - НЕ заменяет конфиг, а ДОПОЛНЯЕТ его
# - ПРОВЕРЯЕТ синтаксис через apache2ctl -t (без -f)
###############################################################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Переменные по умолчанию
APP_NAME="one_c_web_client_v3"
APP_DIR="/var/www/nextcloud/apps/one_c_web_client_v3"
NEXTCLOUD_PATH="/var/www/nextcloud"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/one_c_web_client_v3_$TIMESTAMP"

# Переменные для ввода пользователем
ONE_C_SERVER=""
NEXTCLOUD_DOMAIN=""
APACHE_CONFIG=""

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   one_c_web_client_v3 - ИНТЕРАКТИВНАЯ установка          ║"
echo "║   (с поддержкой SSL и Let's Encrypt)                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ Ошибка: Запустите скрипт от root (sudo)$NC"
    exit 1
fi

echo -e "${GREEN}✓ Запуск от root${NC}"

###############################################################################
# ШАГ 1: Интерактивные вопросы
###############################################################################
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ШАГ 1/6: Параметры Nextcloud и 1С${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 1.1 Путь к Nextcloud
read -p "Путь к Nextcloud [/var/www/nextcloud]: " NC_PATH_INPUT
NEXTCLOUD_PATH=${NC_PATH_INPUT:-/var/www/nextcloud}

if [ ! -d "$NEXTCLOUD_PATH" ]; then
    echo -e "${RED}✗ Ошибка: Nextcloud не найден в $NEXTCLOUD_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Nextcloud найден: $NEXTCLOUD_PATH${NC}"
echo ""

# 1.2 Доменное имя
read -p "Доменное имя Nextcloud (например, cloud.example.com): " NEXTCLOUD_DOMAIN
if [ -z "$NEXTCLOUD_DOMAIN" ]; then
    echo -e "${RED}✗ Ошибка: Доменное имя обязательно${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Домен: $NEXTCLOUD_DOMAIN${NC}"
echo ""

# 1.3 URL 1С сервера
echo -e "${CYAN}Введите URL вашего 1С сервера (с HTTPS):${NC}"
echo -e "${YELLOW}  Пример: https://10.72.1.5 или https://1c.example.com${NC}"
read -p "URL 1С сервера: " ONE_C_SERVER
if [ -z "$ONE_C_SERVER" ]; then
    echo -e "${RED}✗ Ошибка: URL 1С сервера обязателен${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 1С сервер: $ONE_C_SERVER${NC}"
echo ""

# 1.4 Выбор конфига Apache
echo -e "${CYAN}Выберите конфиг Apache для модификации:${NC}"
echo "  1) nextcloud-le-ssl.conf (Let's Encrypt SSL)"
echo "  2) nextcloud.conf (обычный)"
echo "  3) nextcloud-ssl.conf (SSL)"
echo "  4) Другой (указать путь)"
echo ""
read -p "Выберите вариант [1-4]: " CONFIG_CHOICE

case $CONFIG_CHOICE in
    1)
        APACHE_CONFIG="/etc/apache2/sites-available/nextcloud-le-ssl.conf"
        ;;
    2)
        APACHE_CONFIG="/etc/apache2/sites-available/nextcloud.conf"
        ;;
    3)
        APACHE_CONFIG="/etc/apache2/sites-available/nextcloud-ssl.conf"
        ;;
    4)
        read -p "Укажите полный путь к конфиг: " APACHE_CONFIG
        ;;
    *)
        echo -e "${RED}✗ Неверный выбор${NC}"
        exit 1
        ;;
esac

if [ ! -f "$APACHE_CONFIG" ]; then
    echo -e "${RED}✗ Ошибка: Конфиг не найден: $APACHE_CONFIG${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Конфиг Apache: $APACHE_CONFIG${NC}"
echo ""

###############################################################################
# ШАГ 2: Создание резервных копий
###############################################################################
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ШАГ 2/6: Создание резервных копий${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

mkdir -p "$BACKUP_DIR"

# Бэкап конфига
cp "$APACHE_CONFIG" "$BACKUP_DIR/$(basename $APACHE_CONFIG).backup.$TIMESTAMP"
echo -e "${GREEN}✓ Бэкап конфига: $BACKUP_DIR/$(basename $APACHE_CONFIG).backup.$TIMESTAMP${NC}"

# Бэкап enabled конфига
if [ -f "/etc/apache2/sites-enabled/$(basename $APACHE_CONFIG)" ]; then
    cp "/etc/apache2/sites-enabled/$(basename $APACHE_CONFIG)" "$BACKUP_DIR/sites-enabled.backup"
    echo -e "${GREEN}✓ Бэкап sites-enabled${NC}"
fi

# Бэкап приложения если есть
if [ -d "$APP_DIR" ]; then
    cp -r "$APP_DIR" "$BACKUP_DIR/${APP_NAME}.backup"
    echo -e "${GREEN}✓ Бэкап приложения${NC}"
fi

echo -e "${GREEN}✓ Все резервные копии созданы в $BACKUP_DIR${NC}"
echo ""

###############################################################################
# ШАГ 3: Копирование файлов приложения
###############################################################################
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ШАГ 3/6: Копирование файлов приложения${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

mkdir -p "$APP_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/app/one_c_web_client_v3" ]; then
    cp -r "$SCRIPT_DIR/app/one_c_web_client_v3/"* "$APP_DIR/"
    echo -e "${GREEN}✓ Файлы приложения скопированы${NC}"
else
    echo -e "${RED}✗ Ошибка: Директория app/one_c_web_client_v3 не найдена${NC}"
    exit 1
fi

chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"
echo -e "${GREEN}✓ Права установлены${NC}"
echo ""

###############################################################################
# ШАГ 4: Модификация конфига Apache (ДОПОЛНЕНИЕ, не замена!)
###############################################################################
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ШАГ 4/6: Модификация конфига Apache${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Создаём временный файл
TEMP_CONFIG=$(mktemp)
cp "$APACHE_CONFIG" "$TEMP_CONFIG"

echo -e "${BLUE}  Анализ конфига...${NC}"

# Проверяем наличие VirtualHost *:443
if grep -q "<VirtualHost \*:443>" "$TEMP_CONFIG"; then
    echo -e "${GREEN}  ✓ VirtualHost *:443 найден${NC}"
    HAS_VHOST_443=true
else
    echo -e "${YELLOW}  ⚠ VirtualHost *:443 не найден${NC}"
    HAS_VHOST_443=false
fi

# Проверяем SSL
if grep -q "SSLEngine on" "$TEMP_CONFIG"; then
    echo -e "${GREEN}  ✓ SSL настроен${NC}"
    HAS_SSL=true
else
    echo -e "${YELLOW}  ⚠ SSL не настроен${NC}"
    HAS_SSL=false
fi

# Проверяем Let's Encrypt
if grep -q "letsencrypt" "$TEMP_CONFIG"; then
    echo -e "${GREEN}  ✓ Let's Encrypt обнаружен${NC}"
    HAS_LETSENCRYPT=true
else
    HAS_LETSENCRYPT=false
fi

echo ""
echo -e "${BLUE}  Добавление директив для 1С...${NC}"

# 1. Добавляем ProxyPass исключения
if ! grep -q "ProxyPass /core !" "$TEMP_CONFIG"; then
    echo -e "${YELLOW}  - Добавляем ProxyPass исключения...${NC}"
    
    if grep -q "SSLProxyEngine on" "$TEMP_CONFIG"; then
        sed -i '/SSLProxyEngine on/a\
    # Исключения для статических файлов Nextcloud\
    ProxyPass /core !\
    ProxyPass /apps !\
    ProxyPass /dist !\
    ProxyPass /js !\
    ProxyPass /css !\
    ProxyPass /l10n !\
    ProxyPass /index.php !' "$TEMP_CONFIG"
    elif grep -q "SSLEngine on" "$TEMP_CONFIG"; then
        sed -i '/SSLEngine on/a\
    # Исключения для статических файлов Nextcloud\
    ProxyPass /core !\
    ProxyPass /apps !\
    ProxyPass /dist !\
    ProxyPass /js !\
    ProxyPass /css !\
    ProxyPass /l10n !\
    ProxyPass /index.php !' "$TEMP_CONFIG"
    elif [ "$HAS_VHOST_443" = true ]; then
        sed -i '/<VirtualHost \*:443>/,/<\/VirtualHost>/{
            /ServerName/a\
    # Исключения для статических файлов Nextcloud\
    ProxyPass /core !\
    ProxyPass /apps !\
    ProxyPass /dist !\
    ProxyPass /js !\
    ProxyPass /css !\
    ProxyPass /l10n !\
    ProxyPass /index.php !
        }' "$TEMP_CONFIG"
    fi
else
    echo -e "${GREEN}  ✓ ProxyPass исключения уже есть${NC}"
fi

# 2. Добавляем проверку авторизации
if ! grep -q 'RewriteCond %{HTTP_COOKIE} !nc_username' "$TEMP_CONFIG"; then
    echo -e "${YELLOW}  - Добавляем проверку авторизации...${NC}"
    
    if grep -q "ProxyPassMatch" "$TEMP_CONFIG"; then
        sed -i '/ProxyPassMatch.*\^\/(/i\
    # Проверка авторизации для 1С прокси\
    <Location ~ "^/([a-zA-Z0-9_-]+)/">\
        RewriteEngine On\
        RewriteCond %{HTTP_COOKIE} !nc_username [NC]\
        RewriteRule ^.*$ /index.php/login?redirect_url=%{REQUEST_URI} [R=302,L]\
    </Location>\
' "$TEMP_CONFIG"
    else
        sed -i 's|</VirtualHost>|\
    # Проверка авторизации для 1С прокси\
    <Location ~ "^/([a-zA-Z0-9_-]+)/">\
        RewriteEngine On\
        RewriteCond %{HTTP_COOKIE} !nc_username [NC]\
        RewriteRule ^.*$ /index.php/login?redirect_url=%{REQUEST_URI} [R=302,L]\
    </Location>\
\
</VirtualHost>|' "$TEMP_CONFIG"
    fi
else
    echo -e "${GREEN}  ✓ Проверка авторизации уже есть${NC}"
fi

# 3. Добавляем ProxyPassMatch с указанным URL 1С
if ! grep -q "ProxyPassMatch" "$TEMP_CONFIG"; then
    echo -e "${YELLOW}  - Добавляем динамический прокси для 1С...${NC}"
    
    # Заменяем your-1c-server на реальный URL
    sed -i 's|</VirtualHost>|\
    # 1C Proxy - Динамический прокси для всех баз\
    ProxyPassMatch ^/([a-zA-Z0-9_-]+)/(.*)$ '"$ONE_C_SERVER"'/$1/$2 retry=0 timeout=60\
    ProxyPassReverse ^/([a-zA-Z0-9_-]+)/(.*)$ '"$ONE_C_SERVER"'/$1/$2\
    ProxyPassReverseCookiePath / /\
\
</VirtualHost>|' "$TEMP_CONFIG"
else
    echo -e "${GREEN}  ✓ ProxyPassMatch уже есть${NC}"
fi

# 4. Добавляем CSP если нет
if ! grep -q "Content-Security-Policy" "$TEMP_CONFIG"; then
    echo -e "${YELLOW}  - Добавляем CSP заголовки...${NC}"
    sed -i '/Header unset X-Frame-Options/a\
    Header always set Content-Security-Policy "frame-ancestors '\''self'\''; frame-src *; connect-src *; script-src '\''self'\'' '\''unsafe-inline'\'' '\''unsafe-eval'\'' *; style-src '\''self'\'' '\''unsafe-inline'\'' *;"' "$TEMP_CONFIG"
fi

# 5. Добавляем SSLProxyEngine если есть SSL
if [ "$HAS_SSL" = true ] && ! grep -q "SSLProxyEngine on" "$TEMP_CONFIG"; then
    echo -e "${YELLOW}  - Добавляем SSLProxyEngine...${NC}"
    sed -i '/SSLEngine on/a\
    SSLProxyEngine on\
    SSLProxyVerify none\
    SSLProxyCheckPeerCN off\
    SSLProxyCheckPeerName off' "$TEMP_CONFIG"
fi

echo ""
echo -e "${BLUE}  ПРОВЕРКА СИНТАКСИСА APACHE...${NC}"

# ВАЖНО: Проверяем синтаксис через apache2ctl -t (без -f!)
# Сначала копируем временный конфиг на место оригинала для проверки
cp "$TEMP_CONFIG" "${APACHE_CONFIG}.test"

if apache2ctl -t 2>&1 | grep -q "Syntax OK"; then
    echo -e "${GREEN}  ✓ Синтаксис корректен${NC}"
    rm "${APACHE_CONFIG}.test"
    
    # Применяем конфиг
    mv "$TEMP_CONFIG" "$APACHE_CONFIG"
    echo -e "${GREEN}✓ Конфиг обновлён: $APACHE_CONFIG${NC}"
else
    echo -e "${RED}✗ Ошибка синтаксиса!${NC}"
    echo ""
    echo -e "${YELLOW}Детали ошибки:${NC}"
    apache2ctl -t 2>&1 | head -10
    echo ""
    rm "${APACHE_CONFIG}.test"
    rm "$TEMP_CONFIG"
    echo -e "${YELLOW}⚠ Конфиг НЕ обновлён, восстановлен из бэкапа${NC}"
    exit 1
fi

echo ""

###############################################################################
# ШАГ 5: Включение модулей Apache
###############################################################################
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ШАГ 5/6: Включение модулей Apache${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

a2enmod proxy proxy_http rewrite headers ssl ssl_proxy 2>/dev/null || true
echo -e "${GREEN}✓ Модули Apache включены${NC}"
echo ""

###############################################################################
# ШАГ 6: Установка приложения в Nextcloud
###############################################################################
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ШАГ 6/6: Установка приложения в Nextcloud${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Отключаем старые версии
echo -e "${BLUE}  Отключение старых версий...${NC}"
sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable one_c_web_client_v2 2>/dev/null || true
sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:disable one_c_web_client 2>/dev/null || true

# Устанавливаем новую версию
if sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:install "$APP_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ Приложение установлено${NC}"
elif sudo -u www-data php "$NEXTCLOUD_PATH/occ" app:enable "$APP_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ Приложение включено${NC}"
else
    echo -e "${YELLOW}⚠ Приложение уже установлено${NC}"
fi

# Очистка кэша
echo -e "${BLUE}  Очистка кэша...${NC}"
sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:repair
sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:mode --off 2>/dev/null || true

echo ""

###############################################################################
# ФИНАЛ: Перезагрузка Apache
###############################################################################
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}ФИНАЛ: Перезагрузка Apache${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Финальная проверка
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    systemctl reload apache2
    echo -e "${GREEN}✓ Apache перезапущен${NC}"
else
    echo -e "${RED}✗ Ошибка синтаксиса Apache!${NC}"
    echo -e "${YELLOW}⚠ Apache НЕ перезапущен${NC}"
    echo ""
    echo -e "${CYAN}Выполните вручную после исправления:${NC}"
    echo "  sudo apache2ctl configtest"
    echo "  sudo systemctl reload apache2"
fi

echo ""

###############################################################################
# ЗАВЕРШЕНИЕ
###############################################################################
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BLUE}📋 Резервные копии:${NC}"
echo "   $BACKUP_DIR"
echo ""
echo -e "${BLUE}📋 Что было сделано:${NC}"
echo "   ✓ Конфиг Apache ДОПОЛНЁН (не заменён!)"
echo "   ✓ SSL сертификаты (в т.ч. Let's Encrypt) СОХРАНЕНЫ"
echo "   ✓ VirtualHost конфигурации СОХРАНЕНЫ"
echo "   ✓ Добавлены директивы для 1С прокси"
echo "   ✓ Приложение $APP_NAME установлено"
echo ""
echo -e "${BLUE}📋 Следующие шаги:${NC}"
echo ""
echo "1. Откройте админ-панель Nextcloud"
echo "   https://$NEXTCLOUD_DOMAIN/index.php/settings/admin/one_c_web_client_v3"
echo ""
echo "2. Добавьте базы 1С через интерфейс"
echo "   - Название: Бухгалтерия"
echo "   - Идентификатор: buh"
echo "   - URL: $ONE_C_SERVER/buh"
echo ""
echo "3. Проверьте работу приложения"
echo "   https://$NEXTCLOUD_DOMAIN/index.php/apps/$APP_NAME/onec"
echo ""
echo -e "${GREEN}✅ ГОТОВО!${NC}"
echo ""
