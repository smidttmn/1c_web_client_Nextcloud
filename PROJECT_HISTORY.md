# История проекта one_c_web_client

## Создание приложения
Приложение создано для интеграции 1С с Nextcloud. Позволяет администраторам настраивать список баз 1С, а пользователям открывать их во фрейме внутри Nextcloud.

## Хронология решений

### 1. Начальная разработка
- Создана структура приложения: Controller, Service, Settings
- Разработаны административные настройки для ввода списка баз
- Создана клиентская часть с кнопками баз
- Реализовано открытие 1С во фрейме

### 2. Проблема: CSP блокировка
**Ошибка:** `Executing inline script violates the following Content Security Policy directive`

**Решение:**
- Вынесен JavaScript в отдельный файл `js/index.js`
- Подключение через `Util::addScript()` вместо inline script
- Добавлен nonce через шаблонизатор Nextcloud

### 3. Проблема: Mixed Content
**Ошибка:** `The page was loaded over HTTPS, but requested an insecure frame 'http://10.72.1.5/sgtbuh'`

**Причина:** Nextcloud работает по HTTPS, 1С серверы только по HTTP

**Решение 1 (попытка):** Apache Reverse Proxy
```apache
ProxyPass /1c-proxy/10.72.1.5/ http://10.72.1.5/
ProxyPassReverse /1c-proxy/10.72.1.5/ http://10.72.1.5/
```

**Проблема:** Nextcloud блокирует запросы к прокси

**Решение 2 (попытка):** Отдельный VirtualHost на порту 8443
```apache
<VirtualHost *:8443>
    ProxyPass /1c-proxy/10.72.1.5/ http://10.72.1.5/
</VirtualHost>
```

**Проблема:** SSL не настроен для порта 8443

**Решение 3 (финальное):** HTTP прокси на том же домене
```javascript
frameUrl = url.replace('http://10.72.1.5/', '/1c-proxy/10.72.1.5/');
```

### 4. Проблема: Блокировка фреймов CSP
**Ошибка:** `Framing 'https://cloud.smidt.keenetic.pro:8443/' violates the following Content Security Policy directive: "frame-src 'self'"`

**Решение:** Добавление разрешений в PageController.php
```php
$csp = new ContentSecurityPolicy();
$csp->addAllowedFrameDomain('http://10.72.1.5');
$csp->addAllowedFrameDomain('https://10.72.1.5');
$csp->addAllowedFrameDomain('https://cloud.smidt.keenetic.pro:8443');
$csp->addAllowedFrameDomain('https://cloud.smidt.keenetic.pro');
```

### 5. Проблема: X-Frame-Options
**Ошибка:** Apache отправляет `X-Frame-Options: SAMEORIGIN`

**Решение:** Удаление заголовка в конфигурации прокси
```apache
Header unset X-Frame-Options
Header set Content-Security-Policy "frame-ancestors 'self' https://cloud.smidt.keenetic.pro:8443"
```

### 6. Проблема: Переписывание URL в HTML
**Проблема:** 1С загружает скрипты напрямую, а не через прокси

**Решение:** mod_substitute для переписывания URL
```apache
AddOutputFilterByType SUBSTITUTE text/html
Substitute "s|<head>|<head><base href=\"/1c-proxy/10.72.1.5/\">|ni"
Substitute "s|http://10.72.1.5/|/1c-proxy/10.72.1.5/|ni"
```

## Финальная конфигурация

### Apache (/etc/apache2/sites-available/nextcloud.conf)
```apache
# 1C Proxy
<Location /1c-proxy/10.72.1.5/>
    Require all granted
    ProxyPass http://10.72.1.5/ retry=0 timeout=60
    ProxyPassReverse http://10.72.1.5/
    Header set Access-Control-Allow-Origin "*"
    Header unset X-Frame-Options
    
    AddOutputFilterByType SUBSTITUTE text/html
    Substitute "s|<head>|<head><base href=\"/1c-proxy/10.72.1.5/\">|ni"
    Substitute "s|http://10.72.1.5/|/1c-proxy/10.72.1.5/|ni"
</Location>
```

### PageController.php
```php
$csp = new ContentSecurityPolicy();
$csp->addAllowedFrameDomain('http://10.72.1.5');
$csp->addAllowedFrameDomain('https://10.72.1.5');
$csp->addAllowedFrameDomain('https://cloud.smidt.keenetic.pro');
$response->setContentSecurityPolicy($csp);
```

### JavaScript (index.js)
```javascript
if (url.startsWith('http://10.72.1.5/')) {
    frameUrl = url.replace('http://10.72.1.5/', '/1c-proxy/10.72.1.5/');
}
frame.src = frameUrl;
```

## Принцип работы (аналог Keenetic)
```
Браузер (HTTPS) 
    ↓
Nextcloud + Apache Proxy 
    ↓ (HTTP внутри сети)
1С сервер (10.72.1.5)
    ↓
Ответ через прокси
    ↓
Браузер (HTTPS)
```

## Ключевые файлы
- Приложение: `/home/smidt/nc1c/`
- Установка: `/var/www/nextcloud/apps/one_c_web_client/`
- Конфигурация Apache: `/etc/apache2/sites-available/nextcloud.conf`

## Дата завершения
Февраль 2026
