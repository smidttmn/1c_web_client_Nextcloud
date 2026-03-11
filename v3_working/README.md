# one_c_web_client_v3

**Интеграция 1С:Предприятие с Nextcloud - Версия 3**

[![Nextcloud](https://img.shields.io/badge/Nextcloud-32.0.5-blue)](https://nextcloud.com)
[![PHP](https://img.shields.io/badge/PHP-7.4+-purple)](https://php.net)
[![License](https://img.shields.io/badge/License-AGPLv3-green)](LICENSE)

---

## 📖 Описание

Приложение для доступа к системам 1С:Предприятие прямо из интерфейса Nextcloud.

**Версия 3** - полностью готовое решение с динамическим прокси и защитой от неавторизованного доступа!

### ✨ Возможности

- 🔐 **Динамический прокси** - добавляйте базы 1С без изменения конфига Apache
- 🔒 **Защита от неавторизованного доступа** - проверка авторизации Nextcloud
- 🎨 **Красивый адаптивный интерфейс** - работает на ПК и мобильных
- 📊 **Админ-панель** - настройка списка баз через веб-интерфейс
- 🚀 **Быстрая установка** - автоматический установщик
- 🔄 **Cookie проксирование** - корректная работа сессий 1С

---

## 📋 Требования

- Nextcloud 31 или 32
- Apache с модулями: `mod_proxy`, `mod_proxy_http`, `mod_rewrite`, `mod_headers`
- PHP 7.4+
- HTTPS на сервере Nextcloud
- HTTPS на сервере 1С:Предприятие

---

## 🚀 Быстрая установка

### 1. Автоматическая установка

```bash
# Скачайте и распакуйте архив
cd /tmp
tar -xzf one_c_web_client_v3.tar.gz
cd one_c_web_client_v3

# Запустите установщик от root
sudo ./install.sh
```

### 2. Ручная установка

```bash
# Скопируйте файлы приложения
cp -r one_c_web_client_v3 /var/www/nextcloud/apps/

# Установите права
chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client_v3

# Установите приложение
sudo -u www-data php /var/www/nextcloud/occ app:install one_c_web_client_v3

# Включите модули Apache
a2enmod proxy proxy_http rewrite headers

# Перезапустите Apache
systemctl restart apache2
```

---

## ⚙️ Настройка

### 1. Настройка Apache

Конфигурация Apache уже включена в дистрибутив (`apache_nextcloud.conf`).

**Важно:** Убедитесь, что `ProxyPass` исключения расположены **ДО** `ProxyPassMatch`:

```apache
# Исключения (ДО ProxyPassMatch!)
ProxyPass /core !
ProxyPass /apps !
ProxyPass /dist !
ProxyPass /js !
ProxyPass /css !
ProxyPass /l10n !
ProxyPass /index.php !

# Проверка авторизации
<Location ~ "^/([a-zA-Z0-9_-]+)/">
    RewriteEngine On
    RewriteCond %{HTTP_COOKIE} !nc_username [NC]
    RewriteRule ^.*$ /index.php/login?redirect_url=%{REQUEST_URI} [R=302,L]
</Location>

# Динамический прокси для 1С
ProxyPassMatch ^/([a-zA-Z0-9_-]+)/(.*)$ https://10.72.1.5/$1/$2 retry=0 timeout=60
ProxyPassReverse ^/([a-zA-Z0-9_-]+)/(.*)$ https://10.72.1.5/$1/$2
ProxyPassReverseCookiePath / /
```

### 2. Добавление баз 1С

1. Откройте админ-панель:
   ```
   https://your-nextcloud-domain/index.php/settings/admin/one_c_web_client_v3
   ```

2. Нажмите **"+ Добавить базу"**

3. Заполните поля:
   - **Название:** Бухгалтерия (отображается в кнопке)
   - **Идентификатор:** `buh` (латиницей, должен совпадать с путём в 1С!)
   - **URL:** `https://10.72.1.5/buh` (полный URL до базы)

4. Нажмите **"Сохранить"**

### 3. Проверка работы

1. Откройте приложение:
   ```
   https://your-nextcloud-domain/index.php/apps/one_c_web_client_v3/onec
   ```

2. Выберите базу из списка

3. 1С откроется в новом окне

---

## 🔒 Безопасность

### Проверка защиты

1. Откройте режим инкогнито в браузере

2. Попробуйте зайти напрямую:
   ```
   https://your-nextcloud-domain/buh/
   ```

3. Должен быть редирект на страницу входа Nextcloud

4. После авторизации - 1С откроется

### Как это работает

- Apache проверяет cookie `nc_username` для всех запросов к базам 1С
- Если cookie нет - редирект на `/index.php/login`
- После входа - запрос проксируется на сервер 1С

---

## 📁 Структура приложения

```
one_c_web_client_v3/
├── appinfo/
│   ├── info.xml              # Описание приложения
│   └── routes.php            # Маршруты
├── lib/
│   ├── Controller/
│   │   ├── PageController.php       # Главная страница
│   │   ├── ConfigController.php     # API настроек
│   │   └── ProxyController.php      # Прокси с проверкой
│   └── Settings/
│       ├── AdminSettings.php        # Админ-панель
│       └── AdminSection.php         # Секция настроек
├── templates/
│   ├── index.php                    # Пользовательская часть
│   └── admin_settings.php           # Админ-панель
├── js/
│   └── index.js                     # Клиентский JS
├── css/
│   └── style.css                    # Стили
└── img/
    └── app.svg                      # Иконка
```

---

## 🔧 Команды управления

```bash
# Включить приложение
sudo -u www-data php /var/www/nextcloud/occ app:enable one_c_web_client_v3

# Отключить приложение
sudo -u www-data php /var/www/nextcloud/occ app:disable one_c_web_client_v3

# Удалить приложение
sudo -u www-data php /var/www/nextcloud/occ app:remove one_c_web_client_v3

# Получить список баз
sudo -u www-data php /var/www/nextcloud/occ config:app:get one_c_web_client_v3 databases

# Установить базы (JSON)
sudo -u www-data php /var/www/nextcloud/occ config:app:set one_c_web_client_v3 databases \
  --value='[{"name":"Бухгалтерия","id":"buh","url":"https://10.72.1.5/buh"}]'

# Очистить кэш
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair
```

---

## 🐛 Решение проблем

### Nextcloud показывает 404 на CSS/JS

**Проблема:** ProxyPassMatch перехватывает статические файлы

**Решение:** Убедитесь, что исключения ProxyPass расположены ДО ProxyPassMatch:

```apache
ProxyPass /core !
ProxyPass /apps !
# ... другие исключения ...
ProxyPassMatch ^/([a-zA-Z0-9_-]+)/(.*)$ ...
```

### Базы не сохраняются

**Проблема:** API возвращает ошибку

**Решение:**
1. Проверьте права на config.php: `chown www-data:www-data config/config.php`
2. Очистите кэш: `occ maintenance:repair`
3. Проверьте логи: `tail -f data/nextcloud.log`

### 1С не открывается без авторизации

**Это не ошибка!** Это защита от неавторизованного доступа.

Для доступа к 1С сначала войдите в Nextcloud.

### Ошибка "OC is not defined"

**Проблема:** Кэш браузера

**Решение:** Очистите кэш браузера (Ctrl+Shift+Delete) или обновите страницу (Ctrl+F5)

---

## 📊 Сравнение версий

| Функция | v1 | v2 | v3 |
|---------|----|----|-----|
| Статический прокси | ✅ | ✅ | ❌ |
| Динамический прокси | ❌ | ❌ | ✅ |
| Админ-панель | ❌ | ✅ | ✅ |
| Защита от неавторизованного доступа | ❌ | ❌ | ✅ |
| Nextcloud 32 | ❌ | ⚠️ | ✅ |
| Автоматический установщик | ❌ | ❌ | ✅ |

---

## 📝 Лицензия

AGPL v3 - см. файл [LICENSE](LICENSE)

---

## 👥 Авторы

Разработано для интеграции Nextcloud с 1С:Предприятие

---

## 📞 Поддержка

- Документация: `README.md`
- Быстрый старт: `QUICK_START.md`
- История проекта: `BEADS_V3_SUCCESS.md`

---

**Версия:** 3.0.0  
**Дата:** Март 2026  
**Nextcloud:** 32.0.5
