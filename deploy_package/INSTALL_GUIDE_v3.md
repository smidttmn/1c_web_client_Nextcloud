# one_c_web_client_v3 - Интерактивный установщик

## 📦 Комплект поставки

В комплекте:
1. **install_interactive.sh** - Интерактивный скрипт установки
2. **one_c_web_client_v3_deploy.tar.gz** - Архив приложения (13KB)
3. **INSTALL_GUIDE.md** - Эта инструкция

---

## 🚀 Быстрая установка

### Шаг 1: Скопируйте файлы на сервер Nextcloud

```bash
# На вашем сервере с Nextcloud
cd /tmp

# Скопируйте файлы (например, через scp)
scp user@your-server:/path/to/one_c_web_client_v3_deploy.tar.gz /tmp/
scp user@your-server:/path/to/install_interactive.sh /tmp/
```

### Шаг 2: Распакуйте приложение

```bash
cd /tmp
tar -xzf one_c_web_client_v3_deploy.tar.gz
```

### Шаг 3: Запустите интерактивный установщик

```bash
# От root
sudo /tmp/install_interactive.sh
```

---

## 📋 Что делает установщик

### 1. Автоопределение конфигурации

Установщик автоматически определяет:
- ✅ Путь к Nextcloud (occ, apps директория)
- ✅ Конфигурацию Apache (sites-available/nextcloud.conf)
- ✅ Доменное имя сервера (ServerName)
- ✅ SSL сертификаты (Let's Encrypt или пользовательские)
- ✅ Отсутствие необходимых модулей Apache

### 2. Интерактивные вопросы

Вам будет предложено:

1. **Путь к Nextcloud** - подтвердите или укажите свой
   ```
   Nextcloud обнаружен в: /var/www/nextcloud
   Путь к Nextcloud [/var/www/nextcloud]:
   ```

2. **Конфиг Apache** - где хранить настройки
   ```
   Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf
   Путь к конфиг Apache [/etc/apache2/sites-available/nextcloud.conf]:
   ```

3. **Доменное имя** - для доступа к Nextcloud
   ```
   Домен сервера: cloud.example.com
   Доменное имя Nextcloud [cloud.example.com]:
   ```

4. **SSL сертификаты** - если обнаружен Let's Encrypt, подставит автоматически
   ```
   ✓ Обнаружен Let's Encrypt SSL
   Сертификаты в: /etc/letsencrypt/live/cloud.example.com/
   ```

5. **1С сервер** - адрес для проксирования
   ```
   Адрес 1С сервера [https://10.72.1.5]:
   ```

6. **Базы 1С** - идентификаторы баз (опционально)
   ```
   База 1С (Enter для завершения): buh
   База 1С (Enter для завершения): zup
   ```

7. **Версия приложения** - выбор между v1 и v3
   ```
   1) one_c_web_client (v1.0.0) - Базовая версия
   2) one_c_web_client_v3 (v3.0.0) - Динамический прокси (рекомендуется)
   ```

### 3. Установка

После подтверждения:

1. **Копирование файлов** в `$NEXTCLOUD_PATH/apps/$APP_NAME`
2. **Настройка Apache**:
   - Создается резервная копия конфига
   - Добавляются ProxyPass правила для 1С
   - Включаются модули: proxy, proxy_http, rewrite, headers, ssl
3. **Установка приложения** через occ
4. **Очистка кэша** (maintenance:repair)
5. **Перезапуск Apache**

### 4. Проверка

Установщик проверяет:
- ✅ Приложение активно в Nextcloud
- ✅ Конфигурация Apache корректна (Syntax OK)
- ✅ SSL сертификаты существуют

---

## 🔧 Ручная установка (альтернатива)

Если интерактивный скрипт не работает:

### 1. Распакуйте приложение

```bash
cd /tmp
tar -xzf one_c_web_client_v3_deploy.tar.gz
```

### 2. Скопируйте в Nextcloud

```bash
sudo cp -r one_c_web_client_v3_clean /var/www/nextcloud/apps/one_c_web_client_v3
sudo chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client_v3
sudo chmod -R 755 /var/www/nextcloud/apps/one_c_web_client_v3
```

### 3. Включите модули Apache

```bash
sudo a2enmod proxy proxy_http rewrite headers ssl
```

### 4. Настройте Apache

Отредактируйте `/etc/apache2/sites-available/nextcloud.conf`:

```apache
<VirtualHost *:443>
    ServerName cloud.example.com
    DocumentRoot /var/www/nextcloud

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/cloud.example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/cloud.example.com/privkey.pem

    # SSL Proxy Settings
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

    # one_c_web_client_v3 - Прокси для 1С
    ProxyPass /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3 retry=0 timeout=60
    ProxyPassReverse /one_c_web_client_v3 https://10.72.1.5/one_c_web_client_v3
    ProxyPassReverseCookiePath / /

    # Разрешение фреймов и CSP
    Header unset X-Frame-Options
    Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; connect-src *; script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;"

    <Directory /var/www/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>
</VirtualHost>
```

### 5. Установите приложение

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install one_c_web_client_v3
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair
sudo systemctl reload apache2
```

---

## 📁 Структура приложения

```
one_c_web_client_v3/
├── appinfo/
│   ├── info.xml          # Метаданные приложения
│   └── routes.php        # Маршруты
├── lib/
│   ├── AppInfo/
│   │   └── Application.php
│   ├── Controller/
│   │   ├── PageController.php      # Главная страница
│   │   ├── ProxyController.php     # Прокси для 1С
│   │   └── ConfigController.php    # Настройки админа
│   └── Settings/
│       ├── AdminSettings.php       # Админ-панель
│       └── AdminSection.php        # Раздел администрирования
├── templates/
│   ├── index.php                   # Шаблон главной страницы
│   └── admin_settings.php          # Шаблон настроек
├── js/
│   └── index.js                    # Клиентский JavaScript
├── l10n/
│   └── ru.json                     # Русские переводы
└── img/
    └── app.svg                     # Иконка приложения
```

---

## ⚙️ Настройка после установки

### 1. Откройте админ-панель

```
https://cloud.example.com/index.php/settings/admin/one_c_web_client_v3
```

### 2. Добавьте базы 1С

Пример:
- **Название**: Бухгалтерия
- **Идентификатор**: buh
- **URL**: https://10.72.1.5/buh

### 3. Проверьте работу

```
https://cloud.example.com/index.php/apps/one_c_web_client_v3/
```

---

## 🔍 Диагностика проблем

### Логи установщика

```bash
cat /tmp/one_c_install_*.log
```

### Логи Nextcloud

```bash
sudo -u www-data php /var/www/nextcloud/occ log:manage --level debug
tail -f /var/www/nextcloud/data/nextcloud.log
```

### Логи Apache

```bash
tail -f /var/log/apache2/error.log
tail -f /var/log/apache2/nextcloud-error.log
```

### Проверка приложения

```bash
# Статус приложения
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c

# Проверка конфига Apache
apache2ctl configtest

# Проверка модулей
a2query -m proxy
a2query -m proxy_http
a2query -m rewrite
```

---

## 🛡️ Безопасность

### Что делает установщик для безопасности:

1. **Резервные копии** - перед изменением создается backup конфига
2. **Проверка синтаксиса** - Apache конфиг проверяется перед применением
3. **Минимальные права** - www-data владелец файлов
4. **SSL Proxy** - безопасное соединение с 1С
5. **Cookie проверка** - защита от неавторизованного доступа

### Дополнительные рекомендации:

1. Ограничьте доступ к 1С только с IP Nextcloud сервера
2. Используйте HTTPS на 1С серверах
3. Настройте firewall правила
4. Регулярно обновляйте приложение

---

## 📞 Поддержка

При проблемах:

1. Проверьте логи: `/tmp/one_c_install_*.log`
2. Запустите диагностику:
   ```bash
   sudo -u www-data php /var/www/nextcloud/occ app:list
   apache2ctl configtest
   ```
3. Откройте issue на GitHub

---

## 📄 Лицензия

AGPL v3

---

**Версия**: 3.1.0  
**Дата**: Март 2026  
**Nextcloud**: 31-32  
**PHP**: 7.4+
