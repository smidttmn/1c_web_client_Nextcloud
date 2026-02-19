# Проект: one_c_web_client - Интеграция 1С с Nextcloud

## Статус: ✅ ЗАВЕРШЕНО

## Основная информация
- **Приложение:** one_c_web_client (1C WebClient)
- **Версия:** 1.0.0
- **Дата создания:** Февраль 2026
- **Статус:** Установлено и работает

## Функционал
1. Административная панель для настройки списка баз 1С
2. Клиентская часть с кнопками для доступа к базам
3. Открытие 1С во фрейме внутри Nextcloud

## Критические решения проблем

### 1. Внутренняя ошибка сервера
- **Проблема:** Старое приложение integration_1c вызывало конфликт
- **Решение:** Удаление старого приложения
```bash
sudo -u www-data php -f /var/www/nextcloud/occ app:disable integration_1c
sudo rm -rf /var/www/nextcloud/apps/integration_1c
```

### 2. Content Security Policy
- **Проблема:** Nextcloud блокировал встроенные скрипты
- **Решение:** Использование Util::addScript() в AdminSettings.php
```php
use OCP\Util;
Util::addScript('one_c_web_client', 'admin_settings');
```

### 3. Отправка формы при добавлении базы
- **Проблема:** Кнопка "Добавить базу" вызывала перезагрузку
- **Решение:** e.preventDefault() и e.stopPropagation()
```javascript
addDbBtn.addEventListener('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    // код добавления
});
```

## Структура проекта
```
/home/smidt/nc1c/
├── appinfo/info.xml
├── lib/
│   ├── AppInfo/Application.php
│   ├── Controller/
│   │   ├── PageController.php
│   │   └── ConfigController.php
│   └── Settings/
│       ├── AdminSettings.php
│       └── AdminSection.php
├── templates/
│   ├── index.php
│   └── admin_settings.php
├── js/admin_settings.js
├── l10n/ru.json, ru.php
└── img/app.svg
```

## Команды управления

### Установка
```bash
sudo cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client
sudo chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client
sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client
```

### Диагностика
```bash
# Статус приложения
sudo -u www-data php -f /var/www/nextcloud/occ app:list | grep one_c

# Логи
sudo tail -n 50 /var/www/nextcloud/data/nextcloud.log

# Очистка кэша
sudo -u www-data php -f /var/www/nextcloud/occ maintenance:repair
```

## URL доступа
- Админка: https://cloud.smidt.keenetic.pro/index.php/settings/admin/one_c_web_client
- Клиент: https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client/

## Конфигурация
Базы хранятся в config.php Nextcloud:
```json
[
    {"name": "Бухгалтерия", "url": "http://10.72.1.5/sgtbuh/"},
    {"name": "ЗУП", "url": "http://10.72.1.5/zupnew/"}
]
```

## Важные принципы
1. Всегда используй Util::addScript() для подключения JS
2. Переводы: t('app', 'string') для JS, $l->t() для PHP
3. CSRF токен обязателен для POST-запросов
4. После изменений выполняй occ maintenance:repair

## Контакты
Разработчик: Nextcloud Team
Документация: /home/smidt/nc1c/PROJECT_DOCUMENTATION.md