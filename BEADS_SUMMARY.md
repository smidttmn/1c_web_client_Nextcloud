# Бусины (Beads) - one_c_web_client

## Краткая справка

### Назначение
Приложение для интеграции 1С с Nextcloud. Открывает базы 1С во фрейме внутри Nextcloud.

### Быстрый доступ
- Админка: `https://cloud.smidt.keenetic.pro/index.php/settings/admin/one_c_web_client`
- Клиент: `https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client/`

### Конфигурация
```bash
# Файлы приложения
/home/smidt/nc1c/
/var/www/nextcloud/apps/one_c_web_client/

# Конфигурация Apache
/etc/apache2/sites-available/nextcloud.conf

# Перезапуск Apache
sudo systemctl restart apache2

# Очистка кэша Nextcloud
sudo -u www-data php -f /var/www/nextcloud/occ maintenance:repair
```

### Решение проблем

#### CSP блокировка
Добавить домены в PageController.php:
```php
$csp->addAllowedFrameDomain('http://10.72.1.5');
$csp->addAllowedFrameDomain('https://cloud.smidt.keenetic.pro');
```

#### Mixed Content
Использовать прокси:
```javascript
frameUrl = url.replace('http://10.72.1.5/', '/1c-proxy/10.72.1.5/');
```

#### X-Frame-Options
Удалить в Apache:
```apache
Header unset X-Frame-Options
```

### Команды диагностики
```bash
# Проверка прокси
curl -I "http://10.72.1.5/sgtbuh/"

# Проверка порта
sudo ss -tlnp | grep 8443

# Логи Apache
sudo tail -n 50 /var/log/apache2/error.log | grep -i proxy
```

### Принцип работы
```
Браузер → HTTPS → Nextcloud/Apache → HTTP → 1С
Браузер ← HTTPS ← Nextcloud/Apache ← HTTP ← 1С
```

### Важные заметки
1. Apache прокси должен быть ДО конфигурации Nextcloud
2. mod_substitute переписывает URL в HTML
3. base tag добавляется для относительных путей
4. CSP настраивается через PageController, не через config.php

### Контакты
Разработчик: Nextcloud Team
Дата: Февраль 2026
Версия: 1.0.0
