# Проект: 1C WebClient для Nextcloud

## Описание
Приложение для интеграции 1С с Nextcloud, позволяющее пользователям получать доступ к различным базам 1С через веб-интерфейс Nextcloud.

## Особенности
- Административный интерфейс для настройки списка баз 1С
- Отображение кнопок баз 1С для пользователей
- Открытие веб-страниц 1С во фрейме внутри Nextcloud
- Поддержка внутренних URL-адресов (например, http://10.72.1.5/sgtbuh/)

## Установка
1. Скопировать директорию приложения в /var/www/nextcloud/apps/:
   ```bash
   sudo cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client
   ```

2. Установить приложение через OCC:
   ```bash
   sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client
   ```

3. Перезапустить веб-сервер (при необходимости):
   ```bash
   sudo systemctl restart apache2
   ```

## Структура файлов
- `appinfo/info.xml` - метаданные приложения
- `appinfo/routes.php` - маршруты приложения
- `lib/AppInfo/Application.php` - основной класс приложения
- `lib/Controller/PageController.php` - контроллер главной страницы
- `lib/Controller/ConfigController.php` - контроллер для сохранения настроек
- `lib/Settings/AdminSettings.php` и `AdminSection.php` - административные настройки
- `templates/index.php` - шаблон главной страницы с кнопками баз
- `templates/admin_settings.php` - шаблон административных настроек
- `img/app.svg` - иконка приложения