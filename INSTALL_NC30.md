# Установка one_c_web_client_v3 на Nextcloud 30

**Версия приложения:** 3.2.1  
**Поддержка:** Nextcloud 30, 31, 32  
**Дата:** 13 марта 2026

---

## 🔧 Исправление ошибки 500

Если вы видите ошибку **500 Internal Server Error**, проверьте логи Nextcloud:

```bash
# Проверка логов Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ log:read

# Или посмотрите логи веб-сервера
tail -f /var/log/apache2/nextcloud/nextcloud_error.log
```

### Частые причины ошибки 500:

1. **Несовместимость версий PHP**
   - Для NC 30 требуется PHP 8.0-8.2
   - Проверка: `php -v`

2. **Отсутствуют зависимости PHP**
   ```bash
   # Установите необходимые расширения
   apt-get install php8.1-xml php8.1-mbstring php8.1-gd php8.1-zip php8.1-curl
   ```

3. **Неправильные права доступа**
   ```bash
   chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3
   chmod -R 755 /var/www/html/nextcloud/apps/one_c_web_client_v3
   ```

4. **Проблемы с кэшем**
   ```bash
   sudo -u www-data php occ maintenance:repair
   sudo -u www-data php occ cache:clear
   ```

---

## 📦 Автоматическая установка

### 1. Скопируйте файлы на сервер

```bash
cd /home/smidt
scp install_production.sh root@drive.technoorganic.info:/tmp/
scp one_c_web_client_v3_nc30_deploy.tar.gz root@drive.technoorganic.info:/tmp/
```

### 2. Запустите установку

```bash
ssh root@drive.technoorganic.info
cd /tmp
chmod +x install_production.sh
./install_production.sh
```

---

## 🔧 Ручная установка для Nextcloud 30

### Шаг 1: Проверка версии Nextcloud

```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ status
```

Должно быть: `"versionstring":"30.x.x"`

### Шаг 2: Распакуйте приложение

```bash
cd /var/www/html/nextcloud/apps
tar -xzf /tmp/one_c_web_client_v3_nc30_deploy.tar.gz
mv one_c_web_client_v3_clean one_c_web_client_v3
chown -R www-data:www-data one_c_web_client_v3
chmod -R 755 one_c_web_client_v3
```

### Шаг 3: Проверка совместимости

Откройте `one_c_web_client_v3/appinfo/info.xml` и убедитесь:

```xml
<dependencies>
    <nextcloud min-version="30" max-version="32"/>
    <php min-version="8.0" max-version="8.3"/>
</dependencies>
```

### Шаг 4: Установите приложение

```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ app:install one_c_web_client_v3
```

Если ошибка - попробуйте включить:

```bash
sudo -u www-data php occ app:enable one_c_web_client_v3
```

### Шаг 5: Очистите кэш

```bash
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ cache:clear
```

### Шаг 6: Настройте Apache

Откройте конфиг:

```bash
nano /etc/apache2/sites-available/nextcloud.conf
```

**Добавьте перед `</VirtualHost>` (для *:443):**

```apache
    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С
    # ===================================================================

    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # Исключения для статических файлов Nextcloud
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

**Проверьте и перезапустите:**

```bash
apache2ctl configtest
systemctl restart apache2
```

---

## ✅ Проверка установки

### 1. Проверьте статус приложения

```bash
sudo -u www-data php occ app:list | grep one_c
```

Должно быть:
```
one_c_web_client_v3: 3.2.1
```

### 2. Проверьте логи Nextcloud

```bash
sudo -u www-data php occ log:read
```

Или посмотрите файл лога:

```bash
tail -100 /var/www/html/nextcloud/data/nextcloud.log
```

### 3. Проверьте Apache

```bash
systemctl status apache2
apache2ctl configtest
```

### 4. Откройте в браузере

**Админ-панель:**
```
https://drive.technoorganic.info/index.php/settings/admin/one_c_web_client_v3
```

**Приложение:**
```
https://drive.technoorganic.info/index.php/apps/one_c_web_client_v3/
```

---

## 🐛 Решение проблем для NC 30

### Ошибка: "App does not exist in database"

**Проблема:** Nextcloud не видит приложение в базе данных

**Решение:**
```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ app:enable --force one_c_web_client_v3
```

### Ошибка: "Class not found"

**Проблема:** Автозагрузка классов не работает

**Решение:**
```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ cache:clear
```

### Ошибка: "App is not compatible with your Nextcloud version"

**Проблема:** Проверка версии не проходит

**Решение:** Проверьте `appinfo/info.xml`:

```xml
<nextcloud min-version="30" max-version="32"/>
```

### Ошибка: "Call to undefined method"

**Проблема:** API Nextcloud изменился

**Решение:** Для NC 30 используйте совместимые методы:
- `Util::addScript()` вместо `$context->injectFn()`
- `TemplateResponse` как в текущей версии

### Белый экран после установки

**Причина:** Ошибка PHP не отображается

**Решение:**
1. Включите отображение ошибок:
   ```bash
   sudo -u www-data php occ config:system:set loglevel --value 0
   ```

2. Проверьте логи:
   ```bash
   tail -f /var/log/apache2/nextcloud/nextcloud_error.log
   ```

3. Проверьте права:
   ```bash
   chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3
   ```

---

## 📋 Отличия для Nextcloud 30

### Совместимость:

| Компонент | NC 30 | NC 31-32 |
|-----------|-------|----------|
| PHP | 8.0-8.2 | 8.1-8.3 |
| Bootstrap API | ✅ IBootstrap | ✅ IBootstrap |
| CSP | ✅ ContentSecurityPolicy | ✅ ContentSecurityPolicy |
| Settings API | ✅ IIconSection | ✅ IIconSection |
| Util::addScript() | ✅ Работает | ✅ Работает |

### Особенности NC 30:

1. **Менее строгая проверка CSP** - но всё равно используйте правильные заголовки
2. **Другие пути к статике** - используйте `Util::addScript()`
3. **Старый Bootstrap API** - но наш код совместим

---

## 📞 Если ничего не помогает

1. **Включите debug режим:**
   ```bash
   sudo -u www-data php occ config:system:set loglevel --value 0
   sudo -u www-data php occ config:system:set debug --value true
   ```

2. **Проверьте все логи:**
   ```bash
   tail -f /var/log/apache2/nextcloud/nextcloud_error.log
   tail -f /var/www/html/nextcloud/data/nextcloud.log
   ```

3. **Переустановите приложение:**
   ```bash
   sudo -u www-data php occ app:remove one_c_web_client_v3
   sudo -u www-data php occ cache:clear
   sudo -u www-data php occ app:install one_c_web_client_v3
   ```

---

**Готово!** Приложение должно работать на Nextcloud 30 🎉
