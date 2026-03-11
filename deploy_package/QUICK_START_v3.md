# one_c_web_client_v3 - Быстрый старт

## 🚀 Установка за 3 команды

```bash
# 1. Перейдите в директорию со скриптом
cd /home/smidt/nc1c

# 2. Запустите интерактивный установщик от root
sudo ./install_interactive.sh

# 3. Следуйте подсказкам
```

---

## 📝 Что нужно указать

При установке скрипт спросит:

| Параметр | Пример | Комментарий |
|----------|--------|-------------|
| Путь к Nextcloud | `/var/www/nextcloud` | Обычно определяется автоматически |
| Конфиг Apache | `/etc/apache2/sites-available/nextcloud.conf` | Существующий или новый |
| Домен | `cloud.example.com` | Для доступа к Nextcloud |
| SSL сертификаты | Авто | Если Let's Encrypt - подставит сам |
| 1С сервер | `https://10.72.1.5` | Адрес вашего 1С сервера |
| Базы 1С | `buh`, `zup` | Идентификаторы баз (как в URL 1С) |
| Версия | `2` (v3) | Рекомендуется v3 |

---

## ✅ Проверка

После установки:

```bash
# Проверьте статус приложения
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c

# Должно вывести:
# one_c_web_client_v3: 3.1.0
```

---

## 🎯 Использование

1. **Откройте админ-панель:**
   ```
   https://cloud.example.com/index.php/settings/admin/one_c_web_client_v3
   ```

2. **Добавьте базы 1С:**
   - Название: Бухгалтерия
   - Идентификатор: buh
   - URL: https://10.72.1.5/buh

3. **Проверьте работу:**
   ```
   https://cloud.example.com/index.php/apps/one_c_web_client_v3/
   ```

---

## 🔍 Если что-то пошло не так

### Логи установщика
```bash
cat /tmp/one_c_install_*.log
```

### Логи Nextcloud
```bash
tail -f /var/www/nextcloud/data/nextcloud.log
```

### Логи Apache
```bash
tail -f /var/log/apache2/error.log
```

### Проверка конфига Apache
```bash
apache2ctl configtest
```

---

## 📦 Что устанавливается

- **Приложение**: `one_c_web_client_v3` в `/var/www/nextcloud/apps/`
- **Apache**: Дополняется конфиг (резервная копия создается)
- **Модули**: proxy, proxy_http, rewrite, headers, ssl

---

## 🆘 Помощь

Полная документация: `INSTALL_GUIDE_v3.md`
