# 🚀 СРОЧНАЯ УСТАНОВКА one_c_web_client_v3 НА ПРОДАКШЕН

## ⚠️ ПРОБЛЕМА

После установки `install_safe.sh` приложение не работает:
- Ошибка **500 Internal Server Error** при открытии `/apps/one_c_web_client_v3/onec`
- Ошибки **404 Not Found** для JS/CSS файлов
- В логе Nextcloud ошибки от `files_trackdownloads` (не связано с нашим приложением!)

---

## 🔍 ПРИЧИНА

`install_safe.sh` из `github_release/v3` **НЕ содержит готового приложения** - там только исходники для сборки!

---

## ✅ РЕШЕНИЕ (2 варианта)

### ВАРИАНТ 1: Быстрая установка из `final_deploy` (РЕКОМЕНДУЕТСЯ)

На тестовом сервере (`cloud.smidt.keenetic.pro`) есть **ГОТОВОЕ приложение**:

```bash
# 1. Создать архив из final_deploy
cd /home/smidt/nc1c/final_deploy
tar -czf /tmp/one_c_web_client_v3_ready.tar.gz one_c_web_client/

# 2. Скопировать на продакшен (10.72.1.111)
scp /tmp/one_c_web_client_v3_ready.tar.gz root@10.72.1.111:/tmp/

# 3. На продакшене выполнить:
cd /tmp
tar -xzf one_c_web_client_v3_ready.tar.gz
cp -r one_c_web_client /var/www/html/nextcloud/apps/one_c_web_client_v3
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3

# 4. Установить приложение
sudo -u www-data php /var/www/html/nextcloud/occ app:install one_c_web_client_v3

# 5. Включить модули Apache
a2enmod proxy proxy_http rewrite headers ssl_proxy

# 6. Перезагрузить Apache
systemctl restart apache2

# 7. Очистить кэш Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:mode --on
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:mode --off
```

---

### ВАРИАНТ 2: Использовать `v3/install.sh` (если нет доступа к тестовому серверу)

```bash
# 1. На тестовом сервере собрать архив:
cd /home/smidt/nc1c/v3
tar -czf /tmp/v3_deploy.tar.gz app/one_c_web_client_v2 install.sh README.md

# 2. Отправить на продакшен
scp /tmp/v3_deploy.tar.gz root@10.72.1.111:/tmp/

# 3. На продакшене:
cd /tmp
tar -xzf v3_deploy.tar.gz

# 4. Запустить установку
sudo ./install.sh
```

---

## 🔧 ДИАГНОСТИКА

После установки проверить:

```bash
# 1. Статус приложения
sudo -u www-data php /var/www/html/nextcloud/occ app:list | grep one_c

# 2. Наличие файлов
ls -la /var/www/html/nextcloud/apps/one_c_web_client_v3/js/

# 3. Проверка Apache конфига
apache2ctl configtest

# 4. Перезагрузка Apache
systemctl restart apache2

# 5. Проверка логов
tail -f /var/www/html/nextcloud/data/nextcloud.log
```

---

## 🛠️ ИСПРАВЛЕНИЕ ОШИБОК

### Ошибка files_trackdownloads (НЕ СВЯЗАНА С НАШИМ ПРИЛОЖЕНИЕМ!)

```bash
# Отключить проблемное приложение
sudo -u www-data php /var/www/html/nextcloud/occ app:disable files_trackdownloads
```

### Ошибка 404 для JS/CSS

```bash
# Перегенерировать кэш ассетов
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair

# Или очистить кэш браузера (Ctrl+Shift+R)
```

### Ошибка 500 при открытии onec

Проверить Apache конфиг:

```bash
# Должны быть ProxyPass исключения ДО ProxyPassMatch
grep -A 20 "ProxyPass" /etc/apache2/sites-available/nextcloud.conf
```

**Правильный порядок:**
```apache
# Исключения (ОБЯЗАТЕЛЬНО ДО ProxyPassMatch!)
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
```

---

## 📋 ПРОВЕРКА РАБОТОСПОСОБНОСТИ

1. Открыть Nextcloud в браузере
2. Нажать на иконку "1С:Предприятие" в меню приложений
3. Должны отобразиться кнопки баз 1С (настраиваются в админке)
4. При нажатии на кнопку - открывается 1С в новом окне

---

## 📞 КОНТАКТЫ

Если возникли проблемы:
1. Проверить логи: `tail -100 /var/www/html/nextcloud/data/nextcloud.log`
2. Проверить Apache: `journalctl -u apache2 -n 50`
3. Проверить статус приложения: `occ app:list | grep one_c`

---

**Версия:** 3.0.2 (FULL AUTO)  
**Дата:** 10 марта 2026  
**Nextcloud:** 30-32  
**1С Сервер:** HTTPS обязательно!
