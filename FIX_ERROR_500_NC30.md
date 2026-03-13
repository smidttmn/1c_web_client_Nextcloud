# 🔧 Исправление ошибки 500 для Nextcloud 30

**Проблема:** При установке приложения появляется ошибка `500 Internal Server Error`

**Версия приложения:** 3.2.1 (с поддержкой NC 30)

---

## 🚀 Быстрое решение

### 1. Проверьте версию Nextcloud

```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ status
```

Если версия **30.x.x** - используйте архив **one_c_web_client_v3_nc30_deploy.tar.gz**

### 2. Переустановите приложение

```bash
# Удалите старую версию
sudo -u www-data php occ app:remove one_c_web_client_v3

# Очистите кэш
sudo -u www-data php occ maintenance:repair
sudo -u www-warning php occ cache:clear

# Установите заново
sudo -u www-data php occ app:install one_c_web_client_v3
```

### 3. Проверьте логи

```bash
# Логи Nextcloud
sudo -u www-data php occ log:read

# Логи Apache
tail -f /var/log/apache2/nextcloud/nextcloud_error.log
```

---

## 📋 Полное решение

### Шаг 1: Проверка требований

**PHP версия для NC 30:**
```bash
php -v
```

Требуется: **PHP 8.0 - 8.2**

**Расширения PHP:**
```bash
php -m | grep -E "xml|mbstring|gd|zip|curl|json"
```

Должны быть: xml, mbstring, gd, zip, curl, json

**Установка расширений (если нет):**
```bash
apt-get update
apt-get install php8.1-xml php8.1-mbstring php8.1-gd php8.1-zip php8.1-curl php8.1-json
systemctl restart php8.1-fpm
systemctl restart apache2
```

### Шаг 2: Проверка прав доступа

```bash
# Проверка владельца
ls -la /var/www/html/nextcloud/apps/one_c_web_client_v3

# Должно быть: www-data:www-data

# Исправление прав
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3
chmod -R 755 /var/www/html/nextcloud/apps/one_c_web_client_v3
```

### Шаг 3: Проверка совместимости приложения

Откройте файл `/var/www/html/nextcloud/apps/one_c_web_client_v3/appinfo/info.xml`:

```xml
<?xml version="1.0"?>
<info>
    <id>one_c_web_client_v3</id>
    <version>3.2.1</version>
    <dependencies>
        <nextcloud min-version="30" max-version="32"/>
        <php min-version="8.0" max-version="8.3"/>
    </dependencies>
</info>
```

**Важно:** `min-version="30"` должно быть для NC 30!

### Шаг 4: Очистка кэша Nextcloud

```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ cache:clear
sudo -u www-data php occ app:list --enabled | grep one_c
```

### Шаг 5: Включение debug режима

Если ошибка остаётся, включите подробное логирование:

```bash
sudo -u www-data php occ config:system:set loglevel --value 0
sudo -u www-data php occ config:system:set debug --value true
```

Теперь посмотрите подробный лог:

```bash
tail -f /var/www/html/nextcloud/data/nextcloud.log
```

---

## 🐛 Частые ошибки и решения

### Ошибка: "App does not exist in database"

**Симптомы:**
```
Error: App one_c_web_client_v3 does not exist in database
```

**Решение:**
```bash
cd /var/www/html/nextcloud
sudo -u www-data php occ app:enable --force one_c_web_client_v3
```

### Ошибка: "Class not found"

**Симптомы:**
```
Error: Class 'OCA\OneCWebClient\AppInfo\Application' not found
```

**Причина:** Автозагрузка классов не работает

**Решение:**
```bash
# Проверьте наличие Application.php
ls -la /var/www/html/nextcloud/apps/one_c_web_client_v3/lib/AppInfo/Application.php

# Проверьте права
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3

# Перестроите автозагрузку
cd /var/www/html/nextcloud
sudo -u www-data php occ maintenance:repair
```

### Ошибка: "App is not compatible"

**Симптомы:**
```
App one_c_web_client_v3 is not compatible with your Nextcloud version
```

**Причина:** Проверка версии не проходит

**Решение:**
1. Проверьте `appinfo/info.xml`:
   ```xml
   <nextcloud min-version="30" max-version="32"/>
   ```

2. Если версия NC 30, должно быть `min-version="30"`

3. Переустановите приложение:
   ```bash
   sudo -u www-data php occ app:remove one_c_web_client_v3
   sudo -u www-data php occ app:install one_c_web_client_v3
   ```

### Ошибка: "Call to undefined method"

**Симптомы:**
```
Error: Call to undefined method OCP\AppFramework\Bootstrap\IRegistrationContext::injectFn()
```

**Причина:** API Nextcloud изменился

**Решение:** Используйте совместимый код:

```php
// ✅ Правильно для NC 30-32
public function register(IRegistrationContext $context): void {
    // Регистрация сервисов
}

// ❌ Неправильно (старый API)
$context->injectFn(...)
```

### Белый экран (Blank Page)

**Причина:** Ошибка PHP не отображается

**Решение:**

1. Включите отображение ошибок:
   ```bash
   sudo -u www-data php occ config:system:set loglevel --value 0
   ```

2. Проверьте логи Apache:
   ```bash
   tail -100 /var/log/apache2/nextcloud/nextcloud_error.log
   ```

3. Проверьте логи Nextcloud:
   ```bash
   sudo -u www-data php occ log:read
   ```

4. Проверьте права на директорию data:
   ```bash
   chown -R www-data:www-data /var/www/html/nextcloud/data
   ```

---

## 🔍 Диагностика

### Полный чек-лист проверки

```bash
#!/bin/bash
# Сохраните как check_nc30.sh и запустите от root

echo "=== Проверка Nextcloud 30 ==="

# 1. Версия Nextcloud
echo "1. Версия Nextcloud:"
sudo -u www-data php occ status

# 2. Версия PHP
echo "2. Версия PHP:"
php -v

# 3. Расширения PHP
echo "3. Расширения PHP:"
php -m | grep -E "xml|mbstring|gd|zip|curl|json"

# 4. Статус приложения
echo "4. Статус приложения:"
sudo -u www-data php occ app:list | grep one_c

# 5. Права доступа
echo "5. Права доступа:"
ls -la /var/www/html/nextcloud/apps/ | grep one_c

# 6. Логи Nextcloud
echo "6. Последние ошибки:"
sudo -u www-data php occ log:read | tail -20

# 7. Apache
echo "7. Статус Apache:"
systemctl status apache2 --no-pager | head -10

echo "=== Проверка завершена ==="
```

---

## 📞 Если ничего не помогает

### 1. Полная переустановка

```bash
# Удалите приложение
sudo -u www-data php occ app:remove one_c_web_client_v3

# Удалите файлы
rm -rf /var/www/html/nextcloud/apps/one_c_web_client_v3

# Очистите кэш
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ cache:clear

# Распакуйте заново
cd /var/www/html/nextcloud/apps
tar -xzf /tmp/one_c_web_client_v3_nc30_deploy.tar.gz
mv one_c_web_client_v3_clean one_c_web_client_v3

# Установите права
chown -R www-data:www-data one_c_web_client_v3
chmod -R 755 one_c_web_client_v3

# Установите приложение
sudo -u www-data php occ app:install one_c_web_client_v3
```

### 2. Проверка на другом сервере

Попробуйте установить на тестовом сервере с той же версией NC 30.

### 3. Запрос помощи

Приложите к запросу:
- Версию Nextcloud: `occ status`
- Версию PHP: `php -v`
- Логи: `occ log:read`
- Скриншот ошибки

---

## ✅ Успешная установка

После устранения ошибки проверьте:

```bash
# Приложение установлено
sudo -u www-data php occ app:list | grep one_c_web_client_v3

# Должно быть:
# one_c_web_client_v3: 3.2.1

# Приложение работает
curl -k https://drive.technoorganic.info/index.php/apps/one_c_web_client_v3/

# Нет ошибок в логах
sudo -u www-data php occ log:read | grep -i error
```

---

**Готово!** Ошибка 500 должна быть исправлена 🎉
