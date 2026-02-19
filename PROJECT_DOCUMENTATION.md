# Проект: 1C WebClient для Nextcloud (one_c_web_client)

## Статус
✅ Приложение успешно разработано, установлено и функционирует

## Описание
Приложение для интеграции 1С с Nextcloud, позволяющее:
- Администратору настраивать список баз 1С через административный интерфейс
- Пользователям получать доступ к базам 1С через кнопки в интерфейсе Nextcloud
- Открывать веб-страницы 1С во фрейме внутри Nextcloud

## Расположение файлов
- Исходный код: `/home/smidt/nc1c/`
- Установленное приложение: `/var/www/nextcloud/apps/one_c_web_client/`

## Структура приложения
```
one_c_web_client/
├── appinfo/
│   ├── info.xml              # Метаданные приложения
│   └── routes.php            # Маршруты приложения
├── lib/
│   ├── AppInfo/
│   │   └── Application.php   # Основной класс приложения
│   ├── Controller/
│   │   ├── PageController.php    # Контроллер главной страницы
│   │   └── ConfigController.php  # Контроллер для сохранения настроек
│   └── Settings/
│       ├── AdminSettings.php     # Административные настройки
│       └── AdminSection.php      # Раздел администрирования
├── templates/
│   ├── index.php             # Клиентская страница с кнопками баз
│   └── admin_settings.php    # Шаблон административных настроек
├── js/
│   └── admin_settings.js     # JavaScript для административной панели
├── l10n/
│   ├── ru.json               # Переводы JavaScript
│   └── ru.php                # Переводы PHP
└── img/
    └── app.svg               # Иконка приложения
```

## История решения проблем

### Проблема 1: Внутренняя ошибка сервера
**Симптом:** При доступе к Nextcloud появлялась ошибка "Внутренняя ошибка сервера"

**Причина:** Старое приложение `integration_1c` конфликтовало с новой версией

**Решение:**
```bash
# Отключение старого приложения
sudo -u www-data php -f /var/www/nextcloud/occ app:disable integration_1c

# Удаление старого приложения
sudo rm -rf /var/www/nextcloud/apps/integration_1c
```

### Проблема 2: Синтаксические ошибки в admin_settings.php
**Симптом:** Ошибки парсера PHP в строках с JavaScript кодом

**Причина:** Неправильное экранирование кавычек при встраивании PHP-переменных в JavaScript

**Решение:** Вынос JavaScript в отдельный файл `js/admin_settings.js` и подключение через `Util::addScript()`

### Проблема 3: Content Security Policy блокировал скрипты
**Симптом:** Ошибка в консоли браузера:
```
Executing inline script violates the following Content Security Policy directive
'script-src-elem 'strict-dynamic' 'nonce-...''
```

**Причина:** Nextcloud использует строгую CSP политику, которая блокирует встроенные скрипты

**Решение:** Использование `Util::addScript()` в AdminSettings.php для правильного подключения JavaScript:
```php
use OCP\Util;

public function getForm(): TemplateResponse {
    // ...
    Util::addScript('one_c_web_client', 'admin_settings');
    // ...
}
```

### Проблема 4: Кнопка "Добавить базу" вызывала отправку формы
**Симптом:** При нажатии на кнопку "Добавить базу" страница перезагружалась

**Причина:** Кнопка внутри формы по умолчанию имеет тип `submit`

**Решение:** Добавление `e.preventDefault()` и `e.stopPropagation()` для обработчика клика:
```javascript
addDbBtn.addEventListener('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    // ...
});
```

### Проблема 5: Отсутствие переводов
**Симптом:** Текст в интерфейсе не переводился

**Решение:** Создание файлов переводов:
- `l10n/ru.json` - для JavaScript переводов
- `l10n/ru.php` - для PHP переводов

## Команды для управления приложением

### Установка приложения
```bash
sudo cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client
sudo chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client
sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client
```

### Включение/отключение
```bash
# Включить
sudo -u www-data php -f /var/www/nextcloud/occ app:enable one_c_web_client

# Отключить
sudo -u www-data php -f /var/www/nextcloud/occ app:disable one_c_web_client
```

### Проверка статуса
```bash
sudo -u www-data php -f /var/www/nextcloud/occ app:list | grep one_c
```

### Очистка кэша
```bash
sudo -u www-data php -f /var/www/nextcloud/occ maintenance:repair
```

## URL приложения
- Клиентская часть: `https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client/`
- Административная панель: `https://cloud.smidt.keenetic.pro/index.php/settings/admin/one_c_web_client`
- API для сохранения: `https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client/config/save`

## Конфигурация баз данных
Базы данных хранятся в конфигурации Nextcloud:
```php
$config->setAppValue('one_c_web_client', 'databases', json_encode($databases));
```

Формат хранения:
```json
[
    {
        "name": "Бухгалтерия",
        "url": "http://10.72.1.5/sgtbuh/"
    },
    {
        "name": "ЗУП",
        "url": "http://10.72.1.5/zupnew/"
    }
]
```

## Важные заметки

1. **CSP (Content Security Policy):** Nextcloud использует строгую политику безопасности. Для разрешения фреймов с внешних доменов добавить в `/etc/apache2/sites-available/nextcloud.conf`:
   ```
   Header always set Content-Security-Policy "frame-src *;"
   ```

2. **JavaScript:** Все скрипты должны подключаться через `Util::addScript()` в контроллере, а не через inline script теги.

3. **Переводы:** Для JavaScript используйте функцию `t('app_id', 'string')`, для PHP - `$l->t('string')`. Файлы переводов: `l10n/ru.json` и `l10n/ru.php`.

4. **Обработчики событий:** Использовать `addEventListener` вместо `onclick` атрибутов для совместимости с CSP.

5. **CSRF Token:** При отправке AJAX-запросов необходимо передавать `requesttoken` в заголовках.

6. **OC объекты:** Объекты Nextcloud (OC.msg, OC.generateUrl, OC.requestToken) могут быть не определены сразу после загрузки страницы. Используйте задержку или проверку на существование.

7. **Формат URL баз:** Поддерживаются только URL, начинающиеся с `http://` или `https://`.

8. **Очистка кэша:** После любых изменений выполнять `occ maintenance:repair`.

## Контакты
Разработчик: Nextcloud Team
Дата создания: Февраль 2026
Версия приложения: 1.0.0