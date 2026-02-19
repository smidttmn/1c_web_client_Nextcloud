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

### Решение Mixed Content
**Временное решение:** Добавлен HTTPS на локальный сервер 1С (10.72.1.5)

**Настройка CSP:**
```php
$csp->addAllowedFrameDomain('http://10.72.1.5');
$csp->addAllowedFrameDomain('https://10.72.1.5');
$csp->addAllowedFrameDomain('http://10.72.1.6');
$csp->addAllowedFrameDomain('https://10.72.1.6');
```

### Команды диагностики
```bash
# Проверка доступности 1С
curl -I "http://10.72.1.5/sgtbuh/"

# Проверка прокси
curl -kI "https://cloud.smidt.keenetic.pro/1c-proxy/10.72.1.5/sgtbuh/"

# Логи Apache
sudo tail -n 50 /var/log/apache2/error.log | grep -i proxy
```

### Принцип работы
```
Браузер (HTTPS) → Nextcloud → HTTPS 1С (10.72.1.5)
Браузер ← Nextcloud ← HTTPS 1С (10.72.1.5)
```

### Важные заметки
1. HTTPS на 1С - временное решение
2. CSP настраивается через PageController
3. Для постоянной работы настроить reverse proxy

### Контакты
Разработчик: Nextcloud Team
Дата: Февраль 2026
Версия: 1.0.0
