# one_c_web_client_v3 - Успешная версия интеграции 1С с Nextcloud

## 📅 Дата: 4 марта 2026 г.

## ✅ Статус: РАБОТАЕТ

---

## 🎯 Достигнутые результаты

### 1. Динамический прокси для всех баз 1С
- **Проблема:** Статические ProxyPass требовали изменения конфига Apache для каждой новой базы
- **Решение:** `ProxyPassMatch ^/([a-zA-Z0-9_-]+)/(.*)$ https://10.72.1.5/$1/$2`
- **Результат:** Любая база добавляется через админ-панель без изменения конфига Apache

### 2. Защита от неавторизованного доступа
- **Проблема:** Прямые ссылки на 1С работали без авторизации в Nextcloud
- **Решение:** Проверка cookie `nc_username` через mod_rewrite
- **Результат:** Неавторизованные пользователи перенаправляются на страницу входа

### 3. Исправление конфликтов со статическими файлами
- **Проблема:** ProxyPassMatch перехватывал CSS/JS файлы Nextcloud
- **Решение:** Исключения `ProxyPass /core !`, `ProxyPass /apps !` и т.д. ДО ProxyPassMatch
- **Результат:** Nextcloud работает корректно, 1С проксируется

### 4. Админ-панель для настройки баз
- **Проблема:** Базы не сохранялись через API
- **Решение:** Исправлен ConfigController с правильной обработкой JSON и @NoAdminRequired
- **Результат:** Администратор добавляет базы через веб-интерфейс

### 5. Работа с Nextcloud 32.0.5
- **Проблема:** ISection не найден, OC is not defined ошибки
- **Решение:** IIconSection вместо ISection, credentials: 'include' в fetch
- **Результат:** Полная совместимость с NC 32

---

## 🔧 Технические детали

### Конфигурация Apache (/etc/apache2/sites-available/nextcloud.conf)

```apache
<VirtualHost *:443>
    ServerName your-nextcloud-domain
    DocumentRoot /var/www/nextcloud

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    # SSL Proxy Settings
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    # Исключения для статических файлов Nextcloud (НЕ проксировать!)
    # Должны быть ДО ProxyPassMatch!
    ProxyPass /core !
    ProxyPass /apps !
    ProxyPass /dist !
    ProxyPass /js !
    ProxyPass /css !
    ProxyPass /l10n !
    ProxyPass /index.php !

    # Проверка авторизации для 1С прокси
    <Location ~ "^/([a-zA-Z0-9_-]+)/">
        RewriteEngine On
        RewriteCond %{HTTP_COOKIE} !nc_username [NC]
        RewriteRule ^.*$ /index.php/login?redirect_url=%{REQUEST_URI} [R=302,L]
    </Location>

    # 1C Proxy - Динамический прокси для всех баз
    ProxyPassMatch ^/([a-zA-Z0-9_-]+)/(.*)$ https://10.72.1.5/$1/$2 retry=0 timeout=60
    ProxyPassReverse ^/([a-zA-Z0-9_-]+)/(.*)$ https://10.72.1.5/$1/$2
    ProxyPassReverseCookiePath / /

    # CSP заголовки
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self' https://your-nextcloud-domain; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    <Directory /var/www/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
    </Directory>
</VirtualHost>
```

### Структура приложения

```
/var/www/nextcloud/apps/one_c_web_client_v2/
├── appinfo/
│   ├── info.xml (namespace: OneCWebClientV2, IIconSection)
│   └── routes.php (page, config, proxy routes)
├── lib/
│   ├── Controller/
│   │   ├── PageController.php (@NoAdminRequired)
│   │   ├── ConfigController.php (saveDatabases, getDatabases)
│   │   └── ProxyController.php (проверка IUserSession)
│   └── Settings/
│       ├── AdminSettings.php
│       └── AdminSection.php (IIconSection)
├── templates/
│   ├── index.php (пользовательская часть)
│   └── admin_settings.php (админ-панель с credentials: 'include')
└── js/
    └── index.js (без дефолтных баз)
```

### Ключевые исправления

1. **ConfigController.php:**
   ```php
   public function saveDatabases(): JSONResponse {
       $json = file_get_contents('php://input');
       $databases = json_decode($json, true) ?? [];
       $this->config->setAppValue('one_c_web_client_v2', 'databases', json_encode($databases, JSON_UNESCAPED_UNICODE));
       return new JSONResponse(['success' => true]);
   }
   ```

2. **admin_settings.php:**
   ```javascript
   fetch(apiUrl, {
       method: 'POST',
       credentials: 'include',  // Отправка cookie сессии
       headers: {'Content-Type': 'application/json'},
       body: JSON.stringify(databases)
   })
   ```

3. **index.js:**
   ```javascript
   if (databases.length === 0) {
       container.innerHTML = '<p>Базы данных не настроены...</p>';
       return;  // Не показывать дефолтные базы
   }
   ```

---

## 📋 Порядок установки новой базы 1С

1. Откройте админ-панель: `https://your-nextcloud-domain/index.php/settings/admin/one_c_web_client_v2`
2. Нажмите "+ Добавить базу"
3. Заполните:
   - **Название:** Бухгалтерия (отображается в кнопке)
   - **Идентификатор:** `buh` (латиницей, совпадает с путём в 1С!)
   - **URL:** `https://10.72.1.5/buh` (полный URL до базы)
4. Нажмите "Сохранить"
5. База появится в приложении: `https://your-nextcloud-domain/index.php/apps/one_c_web_client_v2/onec`

---

## 🔒 Проверка безопасности

1. Откройте режим инкогнито (без авторизации)
2. Попробуйте зайти на `https://your-nextcloud-domain/buh/`
3. Должен быть редирект на `/index.php/login`
4. После входа - 1С открывается

---

## 📊 Статистика проекта

- **Версия:** 3.0.0
- **Nextcloud:** 32.0.5
- **Файлов приложения:** 15+
- **Строк кода:** ~2000
- **Время разработки:** 7 дней
- **Проблем решено:** 10+

---

## 🎓 Уроки

### ✅ Работает:
- ProxyPassMatch для динамических маршрутов
- Исключения ProxyPass ДО основного правила
- Проверка авторизации через RewriteCond + cookie
- @NoAdminRequired для API контроллеров
- credentials: 'include' в fetch для сессии
- IIconSection для Nextcloud 32
- JSON_UNESCAPED_UNICODE для русских названий

### ❌ Не работает:
- @PublicPage для записи в config (нужен @NoAdminRequired)
- ProxyPassMatch без исключений для статики
- setAppValue без перезагрузки приложения
- Дефолтные базы в JS (путают пользователей)

---

## 📍 Расположение файлов

- **Приложение:** `/var/www/nextcloud/apps/one_c_web_client_v2/`
- **Конфиг Apache:** `/etc/apache2/sites-available/nextcloud.conf`
- **Исходники:** `/home/smidt/nc1c/`
- **Архивы:** `/home/smidt/one_c_web_client_v3_deploy.tar.gz`
- **NAS:** `10.72.1.111:/srv/.../Drive_NC_1c/v3/`

---

**ГОТОВО К РАЗВЁРТЫВАНИЮ! ✅**
