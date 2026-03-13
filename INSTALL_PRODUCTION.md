# Установка one_c_web_client_v3 на продакшн-сервер

**Сервер:** drive.technoorganic.info / drive.nppsgt.com  
**Дата:** 13 марта 2026  
**Версия приложения:** 3.2.0

---

## 📦 Подготовка

### 1. Скопируйте файлы на сервер

```bash
# На локальном сервере (где собрано приложение)
cd /home/smidt

# Копируем на продакшн-сервер
scp one_c_web_client_v3_deploy.tar.gz root@drive.technoorganic.info:/tmp/
scp nc1c/install_production.sh root@drive.technoorganic.info:/tmp/
```

### 2. Запустите установку

```bash
# На продакшн-сервере
cd /tmp
chmod +x install_production.sh
sudo ./install_production.sh
```

---

## 🔧 Ручная установка (если скрипт не работает)

### Шаг 1: Распакуйте приложение

```bash
cd /var/www/html/nextcloud/apps
tar -xzf /tmp/one_c_web_client_v3_deploy.tar.gz
mv one_c_web_client_v3_clean one_c_web_client_v3
chown -R www-data:www-data one_c_web_client_v3
chmod -R 755 one_c_web_client_v3
```

### Шаг 2: Включите модули Apache

```bash
a2enmod proxy proxy_http proxy_wstunnel headers rewrite ssl substitute
systemctl restart apache2
```

### Шаг 3: Настройте Apache

Откройте конфиг Apache:

```bash
nano /etc/apache2/sites-available/nextcloud.conf
```

**Добавьте перед закрывающим тегом `</VirtualHost>`** (для *:443):

```apache
    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С
    # ===================================================================

    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # Исключения для статических файлов Nextcloud (ОБЯЗАТЕЛЬНО ДО ProxyPass!)
    ProxyPass /core !
    ProxyPass /apps !
    ProxyPass /dist !
    ProxyPass /js !
    ProxyPass /css !
    ProxyPass /l10n !
    ProxyPass /index.php !
    ProxyPass /loleaflet !
    ProxyPass /browser !
    ProxyPass /hosting !
    ProxyPass /cool !

    # Прокси для 1С сервера: https://10.72.1.5
    ProxyPass /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

    # WebSocket прокси для 1С
    ProxyPass /one_c_web_client_v3/ws wss://10.72.1.5/one_c_web_client_v3/ws retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3/ws wss://10.72.1.5/one_c_web_client_v3/ws

    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    # ===================================================================
    # Конец настроек one_c_web_client_v3
    # ===================================================================
```

**Проверьте синтаксис:**

```bash
apache2ctl configtest
```

Должно быть: `Syntax OK`

**Перезапустите Apache:**

```bash
systemctl restart apache2
```

### Шаг 4: Установите приложение в Nextcloud

```bash
cd /var/www/html/nextcloud

# Отключаем старые версии
sudo -u www-data php occ app:disable one_c_web_client 2>/dev/null || true
sudo -u www-data php occ app:disable one_c_web_client_v2 2>/dev/null || true

# Удаляем старые версии
sudo -u www-data php occ app:remove one_c_web_client 2>/dev/null || true
sudo -u www-data php occ app:remove one_c_web_client_v2 2>/dev/null || true

# Устанавливаем новую версию
sudo -u www-data php occ app:install one_c_web_client_v3

# Очищаем кэш
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ cache:clear
```

---

## ✅ Проверка установки

### 1. Проверьте статус приложения

```bash
sudo -u www-data php /var/www/html/nextcloud/occ app:list | grep one_c
```

Должно быть:
```
one_c_web_client_v3: 3.2.0
```

### 2. Проверьте конфиг Apache

```bash
apache2ctl configtest
```

Должно быть: `Syntax OK`

### 3. Проверьте логи

```bash
tail -f /var/log/apache2/nextcloud/nextcloud_error.log
```

### 4. Откройте админ-панель

Перейдите по адресу:

```
https://drive.technoorganic.info/index.php/settings/admin/one_c_web_client_v3
```

Добавьте базу 1С:
- **Название:** Бухгалтерия (или другое)
- **URL:** https://10.72.1.5/one_c_web_client_v3/

### 5. Проверьте работу

Откройте:

```
https://drive.technoorganic.info/index.php/apps/one_c_web_client_v3/
```

---

## 🔧 Настройка 1С сервера

### На сервере 1С (10.72.1.5):

1. **Убедитесь, что HTTPS работает:**

```bash
curl -k https://10.72.1.5/one_c_web_client_v3/
```

Должен вернуться HTML код страницы.

2. **Разрешите CORS** (если требуется):

Добавьте в настройки веб-сервера 1С заголовки:

```apache
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
Header set Access-Control-Allow-Headers "*"
```

3. **Примите самоподписанный сертификат** (первый вход):

Откройте в браузере:
```
https://10.72.1.5/one_c_web_client_v3/
```

Примите сертификат (добавьте исключение).

---

## 🐛 Решение проблем

### Ошибка: "Syntax error" в Apache

```bash
# Проверьте синтаксис
apache2ctl configtest

# Посмотрите ошибку
journalctl -u apache2 -n 50
```

**Решение:** Убедитесь, что все директивы добавлены **внутри** блока `<VirtualHost *:443>`.

### Ошибка: "Mixed Content"

Браузер блокирует HTTP запросы на HTTPS странице.

**Решение:**
1. Убедитесь, что 1С доступна по **HTTPS**
2. В Chrome: `chrome://settings/content/insecureContent` → разрешить для `drive.technoorganic.info`

### Ошибка: "Connection refused"

Сервер 1С недоступен.

**Решение:**
```bash
# Проверьте доступность с сервера Nextcloud
curl -k https://10.72.1.5/one_c_web_client_v3/

# Проверьте сеть
ping 10.72.1.5
```

### Ошибка: "Application not found"

Приложение не установлено.

**Решение:**
```bash
# Проверьте наличие файлов
ls -la /var/www/html/nextcloud/apps/one_c_web_client_v3/

# Проверьте права
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3/

# Попробуйте установить вручную
sudo -u www-data php /var/www/html/nextcloud/occ app:install one_c_web_client_v3
```

---

## 📞 Контакты

При возникновении проблем:
1. Проверьте логи: `/var/log/apache2/nextcloud/`
2. Проверьте статус: `systemctl status apache2`
3. Проверьте приложение: `sudo -u www-data php occ app:list`

---

## 📝 История изменений

### Версия 3.2.0 (13 марта 2026)
- ✅ Исправлена конфигурация Apache (директивы внутри VirtualHost)
- ✅ Добавлен WebSocket прокси
- ✅ Улучшена обработка ошибок
- ✅ Добавлена резервная копия конфига

### Версия 3.1.1
- ✅ Улучшенная безопасность
- ✅ Надёжная установка

---

**Готово!** Приложение установлено и готово к работе. 🎉
