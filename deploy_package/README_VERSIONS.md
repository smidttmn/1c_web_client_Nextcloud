# one_c_web_client - Интеграция 1С с Nextcloud

[![Nextcloud](https://img.shields.io/badge/Nextcloud-31--32-blue)](https://nextcloud.com)
[![PHP](https://img.shields.io/badge/PHP-7.4+-purple)](https://php.net)
[![License](https://img.shields.io/badge/License-AGPLv3-green)](LICENSE)

---

## 📦 Версии

### v3.1.0 (Текущая, рекомендуется)

**one_c_web_client_v3** - Полностью готовое решение с динамическим прокси

**Возможности:**
- ✅ Динамический прокси для неограниченного количества баз 1С
- ✅ Защита от неавторизованного доступа через cookie Nextcloud
- ✅ Интерактивный установщик с автоопределением конфигурации
- ✅ Админ-панель для настройки баз через веб-интерфейс
- ✅ Красивый адаптивный интерфейс
- ✅ Полная поддержка Nextcloud 31-32

**Файлы:**
- `install_interactive.sh` - Интерактивный установщик
- `one_c_web_client_v3_deploy.tar.gz` - Архив приложения (13KB)
- `INSTALL_GUIDE_v3.md` - Подробная инструкция по установке

**Быстрая установка:**
```bash
sudo ./install_interactive.sh
```

---

### v1.0.0 (Базовая)

**one_c_web_client** - Простая версия для доступа к 1С

**Возможности:**
- ✅ Открытие 1С во фрейме
- ✅ Настройка списка баз через админ-панель
- ✅ Прямое HTTPS подключение к 1С

**Файлы:**
- `one_c_web_client/` - Исходный код приложения
- `final_deploy/` - Готовая версия для деплоя

---

## 🚀 Установка v3.1.0

### Автоматическая (рекомендуется)

```bash
# Запустите интерактивный установщик от root
sudo ./install_interactive.sh
```

Установщик:
1. ⚙️ Автоопределит Nextcloud, Apache, SSL
2. 📝 Запросит настройки в интерактивном режиме
3. 📦 Установит приложение
4. 🔧 Настроит Apache (безопасно дополнит конфиг)
5. ✅ Проверит установку

### Ручная

```bash
# Распакуйте
tar -xzf one_c_web_client_v3_deploy.tar.gz

# Скопируйте в Nextcloud
sudo cp -r one_c_web_client_v3_clean /var/www/nextcloud/apps/one_c_web_client_v3
sudo chown -R www-data:www-data /var/www/nextcloud/apps/one_c_web_client_v3

# Установите
sudo -u www-data php /var/www/nextcloud/occ app:install one_c_web_client_v3
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair

# Включите модули Apache
sudo a2enmod proxy proxy_http rewrite headers ssl
sudo systemctl reload apache2
```

---

## 📋 Требования

- Nextcloud 31 или 32
- Apache с модулями: `mod_proxy`, `mod_proxy_http`, `mod_rewrite`, `mod_headers`, `mod_ssl`
- PHP 7.4+
- HTTPS на сервере Nextcloud
- HTTPS на сервере 1С:Предприятие

---

## ⚙️ Настройка

### 1. Откройте админ-панель

```
https://your-nextcloud-domain/index.php/settings/admin/one_c_web_client_v3
```

### 2. Добавьте базы 1С

| Поле | Значение |
|------|----------|
| Название | Бухгалтерия |
| Идентификатор | buh |
| URL | https://10.72.1.5/buh |

### 3. Проверьте работу

```
https://your-nextcloud-domain/index.php/apps/one_c_web_client_v3/
```

---

## 🔧 Архитектура

### Принцип работы

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Browser   │────▶│  Nextcloud   │────▶│  1C Server  │
│  (HTTPS)    │     │  (Apache)    │     │  (HTTPS)    │
└─────────────┘     └──────────────┘     └─────────────┘
                          │
                    ┌─────▼──────┐
                    │ one_c_web  │
                    │   client   │
                    └────────────┘
```

### Компоненты

**Apache Reverse Proxy:**
- Принимает HTTPS запросы
- Проксирует на 1С сервер
- Переписывает URL (ProxyPassReverse)
- Сохраняет cookie (ProxyPassReverseCookiePath)

**PageController:**
- Открывает главную страницу приложения
- Добавляет JavaScript
- Настраивает CSP

**ProxyController:**
- Динамический прокси для 1С
- Переписывает URL в HTML
- Обрабатывает CORS

**AdminSettings:**
- Админ-панель для настройки баз
- Сохранение в AppConfig

---

## 🔍 Диагностика

### Проверка установки

```bash
# Статус приложения
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c

# Проверка конфига Apache
apache2ctl configtest

# Проверка модулей
a2query -m proxy
a2query -m proxy_http

# Логи Nextcloud
sudo -u www-data php /var/www/nextcloud/occ log:manage --level debug
tail -f /var/www/nextcloud/data/nextcloud.log

# Логи Apache
tail -f /var/log/apache2/error.log
```

### Частые проблемы

**1. Ошибка 500 при загрузке 1С**

Причина: 1С сервер недоступен или неверный URL

Решение:
```bash
# Проверьте доступность 1С
curl -k https://10.72.1.5/buh

# Проверьте логи
tail -f /var/log/apache2/error.log
```

**2. Mixed Content ошибка**

Причина: Nextcloud на HTTPS, 1С на HTTP

Решение:
- Настройте HTTPS на 1С сервере
- Или разрешите mixed content в браузере

**3. CSP блокировка**

Причина: Content Security Policy блокирует фреймы

Решение:
- Проверьте CSP заголовки в Apache конфиге
- Добавьте домен 1С в разрешенные

---

## 📁 Структура проекта

```
nc1c/
├── install_interactive.sh          # Интерактивный установщик v3.1.0
├── one_c_web_client_v3_deploy.tar.gz  # Архив приложения
├── INSTALL_GUIDE_v3.md             # Инструкция по установке
├── README_VERSIONS.md              # Этот файл
│
├── one_c_web_client_v3_clean/      # Исходники v3.1.0
│   ├── appinfo/
│   ├── lib/
│   ├── templates/
│   ├── js/
│   └── l10n/
│
├── one_c_web_client/               # Исходники v1.0.0
├── final_deploy/                   # Готовые версии для деплоя
├── v3_working/                     # Рабочая версия из GitHub
│
└── ...                             # Другие версии и архивы
```

---

## 🛡️ Безопасность

### Рекомендации

1. **HTTPS обязательно** - на Nextcloud и 1С серверах
2. **Ограничьте доступ** - только с IP Nextcloud сервера
3. **Регулярные обновления** - следите за обновлениями
4. **Резервные копии** - перед установкой

### Что делает установщик

- ✅ Создает резервные копии конфига Apache
- ✅ Проверяет синтаксис перед применением
- ✅ Устанавливает минимальные права (www-data)
- ✅ Включает SSL Proxy для безопасного соединения

---

## 📄 Лицензия

AGPL v3

---

## 📞 Поддержка

При проблемах:

1. Проверьте логи: `/tmp/one_c_install_*.log`
2. Запустите диагностику:
   ```bash
   sudo -u www-data php /var/www/nextcloud/occ app:list
   apache2ctl configtest
   ```
3. Откройте issue на GitHub

---

**Версия**: 3.1.0  
**Дата**: Март 2026  
**Nextcloud**: 31-32  
**PHP**: 7.4+
