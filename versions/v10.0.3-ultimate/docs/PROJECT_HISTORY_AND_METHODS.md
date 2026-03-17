# 📚 ИСТОРИЯ РАЗРАБОТКИ one_c_web_client_v3

**Проект:** Интеграция 1С с Nextcloud  
**Сервер:** cloud.smidt.keenetic.pro (Nextcloud 33, PHP 8.4, Apache 2.4.66)  
**1С Сервер:** https://10.72.1.5/ (sgtbuh, zupnew)

---

## 🎯 КЛЮЧЕВЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ

### 1. Маршрутизация Nextcloud

**Проблема:** Приложение возвращало на дашборд при нажатии на иконку.

**Решение:**
- Изменить `appinfo/routes.php`: маршрут `/` вместо `/index`
- Исправить `info.xml`: `<id>one_c_web_client_v3</id>` (совпадает с директорией)
- Исправить `Application.php`: `APP_ID = 'one_c_web_client_v3'`

**Файлы:**
```php
// appinfo/routes.php
return [
    'routes' => [
        ['name' => 'page#index', 'url' => '/', 'verb' => 'GET'],
    ]
];
```

---

### 2. Совместимость с Nextcloud

**Проблема:** Приложение не совместимо с версией сервера (NC 33).

**Решение:**
```xml
<!-- appinfo/info.xml -->
<dependencies>
    <nextcloud min-version="30" max-version="34"/>
</dependencies>
```

---

### 3. Проверка авторизации

**Проблема:** Прямые ссылки на прокси обходили авторизацию.

**Решение:**
```php
// lib/Controller/PageController.php
$user = $this->userSession->getUser();
if ($user === null) {
    return new TemplateResponse('core', '403', [], 'guest');
}

// lib/Controller/ProxyController.php  
$user = $this->userSession->getUser();
if ($user === null) {
    return new DataDisplayResponse(
        'Access denied. Please login to Nextcloud first.', 
        Http::STATUS_UNAUTHORIZED
    );
}
```

---

### 4. Настройка Apache Proxy

**Проблема:** 404 ошибка при открытии 1С.

**Причины:**
1. ProxyPass был ПОСЛЕ исключений (`ProxyPass /core !`)
2. Неправильный URL (со слэшем на конце)
3. Отсутствие ProxyPass для подпутей 1С

**Решение:**
```apache
# ПРАВИЛЬНАЯ КОНФИГУРАЦИЯ
SSLProxyEngine on
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off

# ProxyPass ДО всех исключений!
ProxyPass /one_c_web_client_v3 https://10.72.1.5/ retry=0 timeout=60
ProxyPassReverse /one_c_web_client_v3 https://10.72.1.5/

ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1

# Пути 1С
ProxyPass /sgtbuh https://10.72.1.5/sgtbuh
ProxyPassReverse /sgtbuh https://10.72.1.5/sgtbuh
ProxyPass /sgtbuh/ru https://10.72.1.5/sgtbuh/ru
ProxyPassReverse /sgtbuh/ru https://10.72.1.5/sgtbuh/ru

# ИСКЛЮЧЕНИЯ (после ProxyPass!)
ProxyPass /core !
ProxyPass /apps !
ProxyPass /dist !
# ...

# mod_substitute для переписывания URL
AddOutputFilterByType SUBSTITUTE text/html
Substitute s|href="/|href="/one_c_web_client_v3/|in
Substitute s|src="/|src="/one_c_web_client_v3/|in

# CSP
Header unset X-Frame-Options
Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; ..."
```

---

### 5. JavaScript - открытие через прокси

**Проблема:** JavaScript открывал 1С напрямую по URL из базы данных.

**Решение:**
```javascript
// js/index.js
function openDatabase(url, dbName) {
    const urlObj = new URL(url);
    const proxyPath = '/one_c_web_client_v3' + urlObj.pathname;
    console.log('Opening via proxy:', proxyPath);
    frame.src = proxyPath;
}

// Кнопка "открыть в новом окне"
document.querySelectorAll('a.open-new-window').forEach(link => {
    link.addEventListener('click', function(e) {
        e.preventDefault();
        const url = this.getAttribute('href');
        const urlObj = new URL(url);
        const proxyPath = window.location.origin + '/one_c_web_client_v3' + urlObj.pathname;
        window.open(proxyPath, '_blank');
    });
});
```

---

### 6. Контроль версий и структура

**Проблема:** Файлы приложения не соответствовали структуре Nextcloud.

**Решение:**
```
one_c_web_client_v3/
├── lib/
│   ├── AppInfo/Application.php
│   └── Controller/
│       ├── PageController.php
│       ├── ProxyController.php
│       └── ConfigController.php
├── appinfo/
│   ├── info.xml
│   └── routes.php
├── templates/
│   ├── index.php
│   └── admin_settings.php
├── js/
│   ├── index.js
│   └── admin_settings.js
├── img/
│   └── app.svg
└── l10n/
    └── ru.json
```

---

## 🔧 МЕТОДЫ ОТЛАДКИ

### 1. Проверка состояния

```bash
# Статус приложения
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c

# Проверка файлов
ls -la /var/www/nextcloud/apps/one_c_web_client_v3/

# Проверка синтаксиса PHP
php -l /var/www/nextcloud/apps/one_c_web_client_v3/lib/Controller/PageController.php

# Проверка Apache
apache2ctl configtest
systemctl status apache2
```

### 2. Логи

```bash
# Apache
tail -f /var/log/apache2/error.log
tail -f /var/log/apache2/nextcloud_error.log

# Nextcloud
sudo -u www-data php occ log:manage
tail -f /var/www/nextcloud/data/nextcloud.log
```

### 3. Очистка кэша

```bash
# Nextcloud кэш
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ maintenance:mode --off

# Браузер
Ctrl + Shift + R (полная очистка)
Ctrl + Shift + Delete (очистка всего кэша)
```

### 4. Резервное копирование

```bash
# Перед изменениями Apache
BACKUP_DIR="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /etc/apache2/sites-available/nextcloud-le-ssl.conf "$BACKUP_DIR/apache_config.backup"

# Восстановление
cp "$BACKUP_DIR/apache_config.backup" /etc/apache2/sites-available/nextcloud-le-ssl.conf
```

---

## 📋 ЧЕК-ЛИСТ УСТАНОВКИ

### Перед установкой:
- [ ] Nextcloud работает (статус: installed: true, maintenance: false)
- [ ] Apache работает (статус: active)
- [ ] Модули Apache включены (proxy, proxy_http, headers, rewrite, ssl, substitute)
- [ ] Есть доступ к серверу 1С (curl -k https://10.72.1.5/sgtbuh/)

### Установка:
- [ ] Приложение распаковано в правильную директорию
- [ ] APP_ID совпадает с именем директории
- [ ] info.xml имеет правильный `<id>` и совместимость
- [ ] routes.php имеет маршрут `/`
- [ ] Права установлены (www-data:www-data, 755)

### Настройка прокси:
- [ ] ProxyPass ДО всех исключений
- [ ] ProxyPass без слэша на конце URL
- [ ] ProxyPassMatch для всех путей
- [ ] ProxyPass для подпутей 1С (/sgtbuh/ru, /zupnew/ru)
- [ ] mod_substitute для переписывания URL
- [ ] AllowOverride None
- [ ] CSP настроен
- [ ] X-Frame-Options снят

### Проверка:
- [ ] Приложение активно (occ app:list)
- [ ] Иконка появилась в меню
- [ ] При нажатии не возвращает на дашборд
- [ ] 1С открывается через прокси (проверить в консоли браузера)
- [ ] Кнопка "открыть в новом окне" использует прокси
- [ ] Проверка авторизации работает

---

## ⚠️ ЧАСТЫЕ ОШИБКИ

### 1. 404 Not Found
**Причина:** ProxyPass после исключений или неправильный URL
**Решение:** Переместить ProxyPass ДО исключений, убрать слэш на конце

### 2. Возврат на дашборд
**Причина:** Неправильный маршрут в routes.php
**Решение:** Изменить `/index` на `/`

### 3. App not compatible
**Причина:** Версия NC не указана в info.xml
**Решение:** Установить `min-version="30" max-version="34"`

### 4. 402 Payment Required
**Причина:** 1С требует лицензию или авторизацию
**Решение:** Проверить доступность 1С напрямую

### 5. Mixed Content
**Причина:** HTTP ресурсы на HTTPS странице
**Решение:** Принять самоподписанные сертификаты в браузере

---

## 🎯 УРОКИ

### Что работает:
✅ ProxyPass ДО всех исключений  
✅ Util::addScript() для JavaScript  
✅ Проверка авторизации через IUserSession  
✅ mod_substitute для переписывания URL  
✅ CSP через PageController  
✅ Резервное копирование перед изменениями  

### Что НЕ работает:
❌ ProxyPass ПОСЛЕ исключений  
❌ Inline JavaScript в шаблонах  
❌ Прямые ссылки на 1С без прокси  
❌ app:install вместо app:enable для локальных приложений  
❌ Слэш на конце URL в ProxyPass  

---

**Версия документации:** 1.0.0  
**Дата:** 17 марта 2026  
**Статус:** ✅ РАБОЧАЯ КОНФИГУРАЦИЯ
