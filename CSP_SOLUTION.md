# Решение проблем с CSP (Content Security Policy) в Nextcloud

## Проблема
Nextcloud блокировал загрузку внешних URL во фрейме из-за политики CSP `frame-src 'self'`.

## Решение

### 1. Добавление CSP заголовка через Apache
Добавить в файл конфигурации Apache для Nextcloud:
```bash
echo "Header always set Content-Security-Policy \"frame-src *;\" " >> /etc/apache2/sites-available/nextcloud.conf
sudo systemctl restart apache2
```

### 2. Правильное подключение JavaScript
Использовать `Util::addScript()` в контроллере:
```php
use OCP\Util;

public function index(): TemplateResponse {
    Util::addScript('one_c_web_client', 'index');
    return new TemplateResponse('one_c_web_client', 'index', $params);
}
```

### 3. Обработчики событий
Использовать `addEventListener` вместо `onclick`:
```javascript
// Неправильно: <button onclick="openDatabase(this)">
// Правильно:
button.addEventListener('click', function() {
    // код обработчика
});
```

### 4. Переводы
Выносить все строки в файлы переводов:
- `l10n/ru.json` - для JavaScript
- `l10n/ru.php` - для PHP

### 5. Очистка кэша
После любых изменений:
```bash
sudo -u www-data php -f /var/www/nextcloud/occ maintenance:repair
```

## Итог
- Фреймы с внешних URL загружаются без ошибок CSP
- JavaScript загружается как внешний файл с правильным nonce
- Все переводы работают корректно
- Приложение fully функционально

## Команды для быстрой диагностики
```bash
# Проверка заголовков CSP
curl -I https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client/ | grep -i content-security

# Проверка логов на ошибки CSP
sudo tail -n 50 /var/www/nextcloud/data/nextcloud.log | grep -i csp

# Перезапуск Apache с проверкой конфигурации
sudo apache2ctl configtest && sudo systemctl restart apache2
```