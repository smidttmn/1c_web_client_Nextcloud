# 🚀 СРОЧНАЯ ИНСТРУКЦИЯ ПО УСТАНОВКЕ one_c_web_client_v3

## ⚠️ ПРОБЛЕМА

`install_safe.sh` не работает - там только исходники, а не готовое приложение!

---

## ✅ РЕШЕНИЕ

### Шаг 1: Скачать готовый архив

Архив создан: `/home/smidt/one_c_web_client_v3_deploy.tar.gz` (10KB)

**Отправить на продакшен (10.72.1.111):**

```bash
scp /home/smidt/one_c_web_client_v3_deploy.tar.gz root@10.72.1.111:/tmp/
```

---

### Шаг 2: Установить на продакшене

**На продакшене выполнить:**

```bash
# 1. Распаковать
cd /tmp
tar -xzf one_c_web_client_v3_deploy.tar.gz

# 2. Скопировать в apps Nextcloud
cp -r one_c_web_client_v3 /var/www/html/nextcloud/apps/

# 3. Установить права
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3

# 4. Установить приложение
sudo -u www-data php /var/www/html/nextcloud/occ app:install one_c_web_client_v3

# 5. Включить модули Apache
a2enmod proxy proxy_http rewrite headers ssl_proxy

# 6. Перезагрузить Apache
systemctl restart apache2

# 7. Очистить кэш Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
```

---

### Шаг 3: Настроить Apache

**Добавить в `/etc/apache2/sites-available/nextcloud.conf`** (ДО Directory directive):

```apache
# Исключения для статических файлов Nextcloud
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

# CSP для 1С
<IfModule mod_headers.c>
    Header always set Content-Security-Policy "frame-src *; script-src * 'unsafe-inline' 'unsafe-eval';"
</IfModule>
```

**Перезагрузить Apache:**
```bash
apache2ctl configtest
systemctl restart apache2
```

---

### Шаг 4: Проверить работу

```bash
# Статус приложения
sudo -u www-data php /var/www/html/nextcloud/occ app:list | grep one_c

# Должно показать: one_c_web_client_v3: 3.0.2
```

**В браузере:**
1. Открыть Nextcloud
2. Нажать "1С:Предприятие" в меню приложений
3. Настроить базы в админке
4. Открыть 1С

---

## 🛠️ ИСПРАВЛЕНИЕ ОШИБОК

### Ошибка files_trackdownloads (НЕ НАША!)

```bash
sudo -u www-data php /var/www/html/nextcloud/occ app:disable files_trackdownloads
```

### Ошибка 404 для JS/CSS

```bash
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
```

Очистить кэш браузера: **Ctrl+Shift+R**

### Ошибка 500 при открытии onec

Проверить Apache:
```bash
apache2ctl configtest
tail -f /var/log/apache2/error.log
```

---

## 📞 ЕСЛИ ЧТО-ТО НЕ ТАК

1. Проверить логи Nextcloud:
   ```bash
   tail -100 /var/www/html/nextcloud/data/nextcloud.log
   ```

2. Проверить Apache:
   ```bash
   journalctl -u apache2 -n 50 --no-pager
   ```

3. Проверить конфиг:
   ```bash
   grep -A 5 "ProxyPass" /etc/apache2/sites-available/nextcloud.conf
   ```

---

**Версия:** 3.0.2  
**Дата:** 10 марта 2026  
**Архив:** `/home/smidt/one_c_web_client_v3_deploy.tar.gz`
