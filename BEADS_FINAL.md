# Бусины (Beads) - one_c_web_client

## 📋 Краткая справка

### Назначение
Приложение для интеграции 1С с Nextcloud. Открывает базы 1С во фрейме внутри Nextcloud через HTTPS.

### Статус
✅ **ГОТОВО К РАЗВЕРТЫВАНИЮ**

## 📍 Расположение

**Git репозиторий:** `/home/smidt/nc1c/`  
**Архив:** `/home/smidt/one_c_web_client_deploy.tar.gz` (112 KB)  
**NAS:** `ftp://10.1.72.93/NAS/one_c_web_client_deploy.tar.gz`

## 🚀 Быстрый старт

### Доступ к NAS
```bash
# FTP доступ
ftp://10.1.72.93/NAS/
Логин: groot
Пароль: 211312
```

### Установка
```bash
# 1. Скачать с NAS
scp groot@10.1.72.93:/NAS/one_c_web_client_deploy.tar.gz /tmp/

# 2. Распаковать
sudo tar -xzf /tmp/one_c_web_client_deploy.tar.gz -C /path/to/nextcloud/apps/
sudo mv /path/to/nextcloud/apps/nc1c /path/to/nextcloud/apps/one_c_web_client

# 3. Права
sudo chown -R www-data:www-data one_c_web_client

# 4. Установка
sudo -u www-data php occ app:install one_c_web_client
sudo -u www-data php occ app:enable one_c_web_client
sudo -u www-data php occ maintenance:repair
```

### Настройка
1. Nextcloud → Настройки → Администрирование → **1C WebClient**
2. Добавить базы:
   - `СГТ Бухгалтерия` - `https://10.72.1.5/sgtbuh/`
   - `СГТ Кадры` - `https://10.72.1.5/zupnew/`

## ⚙️ Конфигурация

### Совместимость
- **Nextcloud:** 31-32 версии
- **PHP:** 8.0+
- **1С:** Обязательно HTTPS!

### CSP настройки
```php
// lib/Controller/PageController.php
$csp->addAllowedFrameDomain('https://10.72.1.5');
$csp->addAllowedFrameDomain('https://cloud.smidt.keenetic.pro');
```

## 🛠️ Решение проблем

### Mixed Content
**Решение:** HTTPS на 1С серверах

### CSP блокирует
**Решение:** Добавить домен в PageController.php

### Сертификат не доверяется
**Решение:** Открыть 1С напрямую, принять сертификат

## 📄 Документация

- `README_INSTALLATION.md` - Полная инструкция
- `QUICK_START.md` - Быстрый старт
- `PROJECT_HISTORY_COMPLETE.md` - История
- `UPLOAD_SUCCESS.md` - Загрузка на NAS

## 📊 Статистика

| Параметр | Значение |
|----------|----------|
| Версия | 1.0.0 |
| Файлов | 120+ |
| Размер | 112 KB |
| Дата | Февраль 2026 |
| Лицензия | AGPL v3 |

## 📞 Команды

```bash
# Проверка статуса
sudo -u www-data php occ app:list | grep one_c_web

# Переустановка
sudo -u www-data php occ app:disable one_c_web_client
sudo -u www-data php occ app:enable one_c_web_client

# Логи
sudo tail -f /path/to/nextcloud/data/nextcloud.log
```

---

**Готово к использованию!** ✅

**Версия:** 1.0.0 | **Дата:** Февраль 2026
