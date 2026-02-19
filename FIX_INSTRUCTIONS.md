# Инструкция по исправлению ошибки "Внутренняя ошибка сервера" в Nextcloud

## Текущая проблема
Nextcloud возвращает "Внутренняя ошибка сервера" при попытке доступа к веб-интерфейсу.

## Диагностика
При анализе системы были выявлены следующие потенциальные причины проблемы:

1. Отсутствующие PHP-расширения, особенно `pdo`
2. Неправильные права доступа к файлам и директориям Nextcloud
3. Невозможность чтения конфигурационных файлов из-за ограничений доступа

## Решение

### Шаг 1: Установка недостающих PHP-расширений
Выполните следующую команду от имени пользователя с правами sudo:

```bash
sudo apt update
sudo apt install -y php8.4-common php8.4-curl php8.4-gd php8.4-imagick php8.4-intl php8.4-mbstring php8.4-pdo php8.4-mysql php8.4-sqlite3 php8.4-xml php8.4-zip php8.4-bz2 php8.4-gmp php8.4-ldap
```

После установки перезапустите PHP-FPM и Apache:
```bash
sudo systemctl restart php8.4-fpm
sudo systemctl restart apache2
```

### Шаг 2: Исправление прав доступа к файлам Nextcloud
Выполните следующие команды от имени пользователя с правами sudo:

```bash
# Установка владельца файлов Nextcloud
sudo chown -R www-data:www-data /var/www/nextcloud/

# Установка прав на файлы и директории
sudo find /var/www/nextcloud -type f -exec chmod 644 {} \;
sudo find /var/www/nextcloud -type d -exec chmod 755 {} \;

# Установка особых прав для важных директорий
sudo chmod 770 /var/www/nextcloud/data
sudo chmod 770 /var/www/nextcloud/config
sudo chmod 770 /var/www/nextcloud/apps

# Установка прав на конфигурационный файл
sudo chmod 640 /var/www/nextcloud/config/config.php
```

### Шаг 3: Перезапуск сервисов
После изменения прав доступа перезапустите веб-сервер:

```bash
sudo systemctl restart apache2
```

## Проверка результата
После выполнения всех шагов проверьте, доступен ли теперь Nextcloud:

```bash
curl -I http://localhost
```

Вы должны получить HTTP-ответ 200 или 302 (редирект на страницу входа), а не 500 (внутренняя ошибка сервера).

## Установка приложения one_c_web_client
После успешного восстановления работы Nextcloud можно будет установить наше приложение:

```bash
# Копирование приложения
sudo cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client

# Установка прав доступа к приложению
sudo chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client

# Установка приложения через OCC
sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client
```

## Дополнительная диагностика
Если проблема сохраняется, проверьте логи:

```bash
sudo tail -n 50 /var/log/apache2/error.log
sudo -u www-data php -f /var/www/nextcloud/occ log:tail
```