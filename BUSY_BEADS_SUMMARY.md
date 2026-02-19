# Бусины (Beads) - Проект one_c_web_client

## Краткая справка

### Что сделано
✅ Создано приложение one_c_web_client для интеграции 1С с Nextcloud
✅ Приложение установлено и работает
✅ Административная панель доступна и функциональна
✅ Клиентская часть отображает кнопки баз 1С
✅ При нажатии на кнопку открывается 1С во фрейме

### Ключевые решения проблем

1. **Внутренняя ошибка сервера** → Удалено старое приложение integration_1c
2. **CSP блокировка** → Util::addScript() вместо inline script
3. **Синтаксические ошибки PHP** → Вынос JS в отдельный файл
4. **Перезагрузка формы** → e.preventDefault() для кнопок

### Команды для быстрой диагностики

```bash
# Проверка статуса приложения
echo "Apple0589" | sudo -S -u www-data php -f /var/www/nextcloud/occ app:list | grep one_c

# Просмотр логов Nextcloud
echo "Apple0589" | sudo -S tail -n 50 /var/www/nextcloud/data/nextcloud.log

# Очистка кэша
echo "Apple0589" | sudo -S -u www-data php -f /var/www/nextcloud/occ maintenance:repair

# Перезапуск Apache
echo "Apple0589" | sudo -S systemctl restart apache2
```

### Файлы для редактирования

- Административные настройки: `/home/smidt/nc1c/lib/Settings/AdminSettings.php`
- Шаблон настроек: `/home/smidt/nc1c/templates/admin_settings.php`
- JavaScript: `/home/smidt/nc1c/js/admin_settings.js`
- Переводы: `/home/smidt/nc1c/l10n/`

### URL для доступа

- Админка: https://cloud.smidt.keenetic.pro/index.php/settings/admin/one_c_web_client
- Клиент: https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client/

### Пример конфигурации баз

```
Название: Бухгалтерия
URL: http://10.72.1.5/sgtbuh/

Название: ЗУП
URL: http://10.72.1.5/zupnew/
```

### Важные напоминания

1. После изменений в коде всегда выполняй `occ maintenance:repair`
2. Для JavaScript используй только `Util::addScript()`
3. Переводы через `t('one_c_web_client', 'string')` для JS
4. Переводы через `$l->t('string')` для PHP
5. CSRF токен обязателен для POST-запросов

## История изменений

### Версия 1.0.0 (Февраль 2026)
- Первоначальная разработка
- Реализована административная панель
- Реализована клиентская часть
- Добавлены переводы на русский язык
- Исправлены проблемы с CSP
- Исправлены проблемы с отправкой формы