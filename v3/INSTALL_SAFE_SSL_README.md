# 🚀 one_c_web_client_v3 - ИНТЕРАКТИВНЫЙ УСТАНОВЩИК С SSL

## ✅ ГОТОВЫЕ ФАЙЛЫ НА СЕТЕВОМ ДИСКЕ

**Путь:** `\\10.72.1.171\L$\Drive_NC_1c\v3\for_danil\`

**Файлы:**
| Файл | Описание |
|------|----------|
| `install_safe_ssl.sh` | **НОВЫЙ** интерактивный установщик с SSL |
| `one_c_web_client_v3_deploy.tar.gz` | Архив с приложением (10 KB) |
| `QUICK_INSTALL.md` | Краткая инструкция по ручной установке |
| `ДЛЯ_ДАНИЛА_ИНСТРУКЦИЯ.md` | Подробная инструкция |

---

## 🔥 НОВЫЙ СКРИПТ: `install_safe_ssl.sh`

### ✨ Возможности:

- ✅ **ИНТЕРАКТИВНЫЙ** - задаёт вопросы при установке
- ✅ **SSL SAFE** - работает с Let's Encrypt SSL
- ✅ **НЕ ЗАМЕНЯЕТ** конфиг, а ДОПОЛНЯЕТ его
- ✅ **ПРОВЕРЯЕТ** синтаксис через `apache2ctl -t` (правильно!)
- ✅ **СОХРАНЯЕТ** все настройки (SSL, домены, VirtualHosts)

### 📋 Вопросы при установке:

1. **Путь к Nextcloud** (по умолчанию `/var/www/nextcloud`)
2. **Доменное имя** (например, `cloud.example.com`)
3. **URL 1С сервера** (например, `https://10.72.1.5`)
4. **Выбор конфига Apache**:
   - `nextcloud-le-ssl.conf` (Let's Encrypt SSL)
   - `nextcloud.conf` (обычный)
   - `nextcloud-ssl.conf` (SSL)
   - Другой (указать путь)

---

## 🚀 КАК ИСПОЛЬЗОВАТЬ НА ПРОДАКШЕНЕ (10.72.1.111)

### Вариант 1: Автоматическая установка (НОВЫЙ СКРИПТ)

```bash
# 1. Скачать файлы с сетевого диска
#    (или скопировать из \\10.72.1.171\L$\Drive_NC_1c\v3\for_danil\)

# 2. Распаковать архив с приложением
cd /tmp
tar -xzf one_c_web_client_v3_deploy.tar.gz

# 3. Запустить интерактивный установщик
sudo ./install_safe_ssl.sh
```

**Скрипт спросит:**
- Путь к Nextcloud → нажмите Enter (по умолчанию)
- Домен → введите `drive.nppsgt.com`
- URL 1С сервера → введите `https://10.72.1.5`
- Выбор конфига → выберите `1` (nextcloud-le-ssl.conf)

**Скрипт сделает:**
- ✅ Бэкап конфига
- ✅ Копирование файлов приложения
- ✅ Дополнение конфига Apache (без замены!)
- ✅ Проверку синтаксиса
- ✅ Включение модулей
- ✅ Установку приложения
- ✅ Очистку кэша
- ✅ Перезагрузку Apache

---

### Вариант 2: Ручная установка (если скрипт не работает)

```bash
# 1. Распаковать архив
cd /tmp
tar -xzf one_c_web_client_v3_deploy.tar.gz
cp -r one_c_web_client_v3 /var/www/html/nextcloud/apps/
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3

# 2. Установить приложение
sudo -u www-data php /var/www/html/nextcloud/occ app:install one_c_web_client_v3

# 3. Включить модули
a2enmod proxy proxy_http rewrite headers ssl ssl_proxy

# 4. Настроить Apache (добавить в nextcloud-le-ssl.conf)
#    (см. файл QUICK_INSTALL.md)

# 5. Перезагрузить Apache
sudo apache2ctl configtest
sudo systemctl restart apache2

# 6. Очистить кэш
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
```

---

## 🔧 ИСПРАВЛЕНИЕ ОШИБОК

### Ошибка files_trackdownloads (НЕ НАША!)

```bash
sudo -u www-data php /var/www/html/nextcloud/occ app:disable files_trackdownloads
```

### Ошибка 404 для JS/CSS

```bash
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
```

Очистить кэш браузера: **Ctrl+Shift+R**

### Ошибка синтаксиса Apache

```bash
# Проверить синтаксис
sudo apache2ctl -t

# Посмотреть детали
sudo apache2ctl -t 2>&1 | head -20
```

---

## ✅ ПРОВЕРКА РАБОТОСПОСОБНОСТИ

```bash
# 1. Статус приложения
sudo -u www-data php /var/www/html/nextcloud/occ app:list | grep one_c
# Должно показать: one_c_web_client_v3: 3.0.3

# 2. Проверка Apache
sudo apache2ctl configtest
# Должно показать: Syntax OK

# 3. Статус Apache
sudo systemctl status apache2
```

**В браузере:**
1. Открыть `https://drive.nppsgt.com`
2. Нажать "1С:Предприятие" в меню
3. Настроить базы в админке
4. Открыть 1С

---

## 📋 ОТЛИЧИЯ ВЕРСИИ 3.0.3

| Версия | Проблемы | Решение в 3.0.3 |
|--------|----------|-----------------|
| 3.0.0 | Заменял конфиг полностью | ✅ ДОПОЛНЯЕТ конфиг |
| 3.0.1 | Не работал с SSL | ✅ Поддержка SSL/Let's Encrypt |
| 3.0.2 | Ошибка `No MPM loaded` | ✅ Проверка через `apache2ctl -t` |
| **3.0.3** | Не было интерактивности | ✅ **Интерактивные вопросы** |

---

## 📞 ЕСЛИ ЧТО-ТО НЕ ТАК

**Пришлите вывод команд:**

```bash
# 1. Статус приложения
sudo -u www-data php /var/www/html/nextcloud/occ app:list | grep one_c

# 2. Проверка Apache
sudo apache2ctl -t

# 3. Логи
tail -50 /var/www/html/nextcloud/data/nextcloud.log | grep -i error
```

---

**Версия:** 3.0.3 (SSL SAFE)  
**Дата:** 10 марта 2026  
**Скрипт:** `install_safe_ssl.sh`  
**Статус:** ✅ ГОТОВО
