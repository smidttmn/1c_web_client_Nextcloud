# Информация о проекте: 1C WebClient для Nextcloud

## Описание
Приложение для интеграции 1С с Nextcloud, позволяющее пользователям получать доступ к различным базам 1С через веб-интерфейс Nextcloud.

## Статус
- Приложение полностью разработано
- Файлы находятся в /home/smidt/nc1c
- Готово к установке в /var/www/nextcloud/apps/one_c_web_client

## Установка
1. Скопировать приложение:
   ```
   sudo cp -r /home/smidt/nc1c /var/www/nextcloud/apps/one_c_web_client
   ```
2. Установить через OCC:
   ```
   sudo -u www-data php -f /var/www/nextcloud/occ app:install one_c_web_client
   ```

## Текущая проблема
Nextcloud возвращает внутреннюю ошибку сервера при попытке доступа. Для диагностики и исправления создан скрипт fix_nextcloud.sh

## Решение проблемы
Выполнить диагностику и восстановление с помощью скрипта:
```
./fix_nextcloud.sh
```

## После исправления ошибки
После устранения проблемы с Nextcloud, установить приложение one_c_web_client