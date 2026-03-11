# one_c_web_client_v3 - Интерактивный установщик

## 📦 Комплект поставки

**Файлы для установки:**

| Файл | Размер | Описание |
|------|--------|----------|
| `install_interactive.sh` | 23 KB | Интерактивный скрипт установки |
| `one_c_web_client_v3_deploy.tar.gz` | 13 KB | Архив приложения |
| `INSTALL_GUIDE_v3.md` | 10 KB | Подробная инструкция |
| `QUICK_START_v3.md` | 3 KB | Быстрый старт |
| `README_VERSIONS.md` | 9 KB | Описание версий |

**Готовый пакет:**
- `one_c_web_client_v3_full.tar.gz` (25 KB) - Всё в одном архиве

---

## 🚀 Возможности установщика

### 1. Автоопределение конфигурации

Установщик автоматически находит:

**Nextcloud:**
- `/var/www/nextcloud`
- `/var/www/html/nextcloud`
- `/var/www/nextcloud-aio/nextcloud`
- `/snap/nextcloud/current/nextcloud`
- `/usr/share/nextcloud`

**Конфиг Apache:**
- `/etc/apache2/sites-available/nextcloud.conf`
- `/etc/apache2/sites-available/nextcloud-le-ssl.conf`
- `/etc/apache2/sites-enabled/nextcloud.conf`
- Другие стандартные расположения

**SSL сертификаты:**
- Определяет Let's Encrypt автоматически
- Извлекает пути из конфига Apache
- Проверяет существование файлов

**Доменное имя:**
- Извлекает из Apache конфига (ServerName)
- Использует hostname как запасной вариант

### 2. Интерактивный режим

**Вопрос 1: Путь к Nextcloud**
```
ℹ Nextcloud обнаружен в: /var/www/nextcloud
Путь к Nextcloud [/var/www/nextcloud]:
✓ Nextcloud найден: /var/www/nextcloud
```

**Вопрос 2: Конфиг Apache**
```
ℹ Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf
Путь к конфиг Apache [/etc/apache2/sites-available/nextcloud.conf]:
✓ Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf
```

**Вопрос 3: Доменное имя**
```
ℹ Домен сервера: cloud.example.com
Доменное имя Nextcloud [cloud.example.com]:
✓ Домен: cloud.example.com
```

**Вопрос 4: SSL сертификаты**
```
✓ Обнаружен Let's Encrypt SSL
ℹ Сертификаты в: /etc/letsencrypt/live/cloud.example.com/
```

Если SSL не найден:
```
ℹ SSL сертификаты:
Путь к SSL сертификату [/path/to/cert.pem]:
Путь к SSL ключу [/path/to/key.pem]:
```

**Вопрос 5: 1С сервер**
```
ℹ Укажите адрес 1С сервера для проксирования
Формат: https://10.72.1.5 или http://192.168.1.100

Адрес 1С сервера [https://10.72.1.5]:
✓ 1С сервер: https://10.72.1.5
```

**Вопрос 6: Базы 1С**
```
ℹ Добавьте идентификаторы баз 1С (как в адресной строке 1С)
Например: buh, zup, ut и т.д.
Вводите по одному, пустая строка - завершение

База 1С (Enter для завершения): buh
ℹ Добавлено: buh
База 1С (Enter для завершения): zup
ℹ Добавлено: zup
База 1С (Enter для завершения):
```

**Вопрос 7: Версия приложения**
```
ℹ Выберите версию приложения для установки:
1) one_c_web_client (v1.0.0) - Базовая версия
2) one_c_web_client_v3 (v3.0.0) - Динамический прокси (рекомендуется)

Выберите версию [1-2]:
✓ Выбрана версия: one_c_web_client_v3 v3.0.0
```

### 3. Безопасная установка

**Шаг 1: Копирование файлов**
- Создание директории приложения
- Копирование файлов из архива
- Установка правильных прав (www-data:www-data)
- Проверка существования файлов

**Шаг 2: Настройка Apache**
- Создание резервной копии конфига
- Проверка типа конфига (полный/простой)
- Безопасное дополнение существующих настроек
- Включение необходимых модулей
- Проверка синтаксиса перед применением

**Шаг 3: Установка приложения**
- Отключение старых версий
- Удаление старых версий
- Установка новой версии через occ
- Очистка кэша (maintenance:repair)

**Шаг 4: Перезапуск Apache**
- Проверка синтаксиса конфига
- Плавный перезапуск (reload)
- Проверка доступности сервера

**Шаг 5: Проверка установки**
- Активность приложения в Nextcloud
- Корректность конфига Apache
- Существование SSL сертификатов

### 4. Логирование

Все действия записываются в лог:
```
/tmp/one_c_install_YYYYMMDD_HHMMSS.log
```

Лог включает:
- Вывод скрипта (stdout + stderr)
- Результаты проверок
- Ошибки и предупреждения
- Итоговый отчет

---

## 🔧 Как работает скрипт

### Функции автоопределения

**find_nextcloud_path()**
- Проверяет стандартные пути
- Ищет через `find /var/www -name "occ"`
- Проверяет наличие `occ` и `apps/`

**find_apache_config()**
- Проверяет стандартные конфиги
- Ищет по ключевым словам (nextcloud, DocumentRoot)
- Проверяет sites-available и sites-enabled

**check_ssl_config()**
- Извлекает пути из конфига Apache
- Определяет Let's Encrypt по пути
- Возвращает информацию в формате: `cert|key|letsencrypt|path`

**get_server_domain()**
- Извлекает ServerName из конфига
- Использует hostname как запасной вариант

**check_apache_modules()**
- Проверяет наличие модулей через `a2query -m`
- Возвращает список отсутствующих

### Функции установки

**backup_config()**
- Создает резервную копию с временной меткой
- Формат: `nextcloud.conf.backup.YYYYMMDD_HHMMSS`

**configure_apache_full()**
- Дополняет существующий VirtualHost
- Добавляет настройки прокси
- Проверяет синтаксис перед записью
- Откат при ошибке

**configure_apache_simple()**
- Создает новый конфиг с нуля
- Включает все необходимые директивы
- Настраивает SSL, Proxy, CSP

**install_nextcloud_app()**
- Отключает старые версии
- Удаляет старые версии
- Устанавливает новую
- Очищает кэш

### Функции проверки

**verify_installation()**
- Проверяет приложение через `occ app:list`
- Проверяет конфиг Apache
- Проверяет SSL сертификаты
- Возвращает количество ошибок

---

## 📋 Примеры использования

### Пример 1: Стандартная установка

```bash
# Запуск от root
sudo ./install_interactive.sh

# Вывод:
╔═══════════════════════════════════════════════════════════╗
║   one_c_web_client - Интерактивный установщик             ║
║   Интеграция 1С:Предприятие с Nextcloud                   ║
╚═══════════════════════════════════════════════════════════╝

ℹ Сбор информации о сервере...
ℹ Nextcloud обнаружен в: /var/www/nextcloud
ℹ Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf
ℹ Домен сервера: cloud.example.com
ℹ Обнаружен Let's Encrypt SSL

[1] Nextcloud обнаружен в: /var/www/nextcloud
Путь к Nextcloud [/var/www/nextcloud]: ← Enter

[2] Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf
Путь к конфиг Apache [/etc/apache2/sites-available/nextcloud.conf]: ← Enter

[3] Домен сервера: cloud.example.com
Доменное имя Nextcloud [cloud.example.com]: ← Enter

[4] ✓ Обнаружен Let's Encrypt SSL
ℹ Сертификаты в: /etc/letsencrypt/live/cloud.example.com/

[5] Адрес 1С сервера [https://10.72.1.5]: ← Enter
✓ 1С сервер: https://10.72.1.5

[6] База 1С (Enter для завершения): buh
ℹ Добавлено: buh
База 1С (Enter для завершения): zup
ℹ Добавлено: zup
База 1С (Enter для завершения): ← Enter

[7] Выберите версию приложения:
1) one_c_web_client (v1.0.0)
2) one_c_web_client_v3 (v3.0.0) - Динамический прокси (рекомендуется)
Выберите версию [1-2]: 2
✓ Выбрана версия: one_c_web_client_v3 v3.0.0

# Далее автоматическая установка...

✓ Установка завершена!
```

### Пример 2: Нестандартный путь

```bash
sudo ./install_interactive.sh

# Вывод:
ℹ Nextcloud обнаружен в: /var/www/nextcloud
Путь к Nextcloud [/var/www/nextcloud]: /opt/nextcloud
✓ Nextcloud найден: /opt/nextcloud

# Далее установка в указанный путь...
```

### Пример 3: Создание нового конфига

```bash
sudo ./install_interactive.sh

# Вывод:
ℹ Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf
Путь к конфиг Apache [/etc/apache2/sites-available/nextcloud.conf]: ← Enter
ℹ Конфиг не найден, будет создан новый
✓ Конфиг Apache: /etc/apache2/sites-available/nextcloud.conf

# Далее создание нового конфига с SSL...
```

---

## 🛡️ Безопасность

### Резервное копирование

Перед любым изменением:
- Копия конфига Apache: `nextcloud.conf.backup.YYYYMMDD_HHMMSS`
- Лог установки: `/tmp/one_c_install_*.log`

### Проверка синтаксиса

Перед записью конфига:
```bash
apache2ctl configtest
```

Если ошибка - откат к резервной копии.

### Минимальные права

После копирования:
```bash
chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client_v3
chmod -R 755 /var/www/nextcloud/apps/one_c_web_client_v3
```

### SSL Proxy

Для безопасного соединения с 1С:
```apache
SSLProxyEngine on
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
```

---

## 🔍 Диагностика

### Просмотр лога установки

```bash
# Последний лог
ls -lt /tmp/one_c_install_*.log | head -1

# Просмотр
cat /tmp/one_c_install_20260311_093000.log
```

### Проверка установки

```bash
# Статус приложения
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c

# Проверка конфига
apache2ctl configtest

# Проверка модулей
a2query -m proxy
a2query -m proxy_http
a2query -m rewrite
```

### Логи Nextcloud

```bash
# Включить debug логирование
sudo -u www-data php /var/www/nextcloud/occ log:manage --level debug

# Просмотр
tail -f /var/www/nextcloud/data/nextcloud.log
```

### Логи Apache

```bash
# Ошибки
tail -f /var/log/apache2/error.log

# Доступ
tail -f /var/log/apache2/access.log
```

---

## 📄 Лицензия

AGPL v3

---

**Версия**: 3.1.0  
**Дата**: Март 2026  
**Nextcloud**: 31-32  
**PHP**: 7.4+
