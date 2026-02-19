# one_c_web_client - Решение Mixed Content

## Проблема
При открытии 1С из Nextcloud (HTTPS) возникает ошибка Mixed Content, так как 1С серверы работают только по HTTP.

## Временное решение
**Добавлен HTTPS на локальный сервер 1С (10.72.1.5)**

Это позволяет браузеру открывать 1С во фрейме без блокировки Mixed Content.

## Настройка CSP
В `lib/Controller/PageController.php` добавлены разрешенные домены:

```php
$csp = new ContentSecurityPolicy();
$csp->addAllowedFrameDomain('http://10.72.1.5');
$csp->addAllowedFrameDomain('https://10.72.1.5');
$csp->addAllowedFrameDomain('http://10.72.1.6');
$csp->addAllowedFrameDomain('https://10.72.1.6');
$response->setContentSecurityPolicy($csp);
```

## Работа приложения
1. Пользователь открывает Nextcloud (HTTPS)
2. Нажимает на кнопку базы 1С
3. JavaScript открывает фрейм с URL 1С (теперь HTTPS)
4. Браузер не блокирует запрос (оба HTTPS)

## Постоянное решение (на будущее)
1. **Nginx Proxy Manager** - настройка reverse proxy с Let's Encrypt
2. **Apache Proxy** - настройка ProxyPass в Apache
3. **Keenetic Pro** - настройка прокси на уровне роутера

## Файлы
- Приложение: `/home/smidt/nc1c/`
- Установка: `/var/www/nextcloud/apps/one_c_web_client/`
- Конфигурация Apache: `/etc/apache2/sites-available/nextcloud.conf`

## Дата
Февраль 2026
