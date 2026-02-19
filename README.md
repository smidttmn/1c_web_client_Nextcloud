# 1C WebClient for Nextcloud

[![Release](https://img.shields.io/github/v/release/smidttmn/one_c_web_client)](https://github.com/smidttmn/one_c_web_client/releases)
[![License](https://img.shields.io/github/license/smidttmn/one_c_web_client)](LICENSE)
[![Nextcloud](https://img.shields.io/badge/Nextcloud-31--32-blue)](https://nextcloud.com)

**1C WebClient** — приложение для интеграции 1С:Предприятие с Nextcloud. Открывайте базы 1С прямо в интерфейсе Nextcloud через защищённое HTTPS-соединение.

![Nextcloud 31-32](https://img.shields.io/badge/Nextcloud-31--32-green)
![1C Compatible](https://img.shields.io/badge/1C-Compatible-blue)

---

## ✨ Возможности

- 🔧 **Настройка баз 1С** через административную панель
- 🖥️ **Открытие 1С во фрейме** внутри интерфейса Nextcloud
- 📚 **Поддержка нескольких баз** данных одновременно
- 🔒 **Безопасное HTTPS-подключение** к серверам 1С
- 🚀 **Автоматическая установка** через скрипт deploy.sh
- 🌐 **Совместимость** с Nextcloud 31 и 32

---

## 📋 Требования

| Компонент | Версия | Примечание |
|-----------|--------|------------|
| **Nextcloud** | 31-32 | Обязательно |
| **PHP** | 7.4+ | |
| **1С** | Любая | HTTPS обязателен! |
| **Доступ** | Сеть | Nextcloud → 1С |

---

## 🚀 Быстрая установка

### Автоматическая (рекомендуется)

```bash
# 1. Скачайте архив и скрипт
wget https://github.com/smidttmn/one_c_web_client/releases/download/v1.0.0/one_c_web_client_deploy.tar.gz
wget https://github.com/smidttmn/one_c_web_client/releases/download/v1.0.0/deploy.sh

# 2. Сделайте скрипт исполняемым
chmod +x deploy.sh

# 3. Запустите установку
sudo ./deploy.sh one_c_web_client_deploy.tar.gz
```

### Ручная

```bash
# 1. Распакуйте в apps Nextcloud
sudo tar -xzf one_c_web_client_deploy.tar.gz -C /path/to/nextcloud/apps/

# 2. Установите права
sudo chown -R www-data:www-data /path/to/nextcloud/apps/one_c_web_client

# 3. Установите приложение
sudo -u www-data php /path/to/nextcloud/occ app:install one_c_web_client
sudo -u www-data php /path/to/nextcloud/occ app:enable one_c_web_client
sudo -u www-data php /path/to/nextcloud/occ maintenance:repair
```

---

## 📖 Настройка

### Добавление базы 1С

1. Откройте Nextcloud как администратор
2. Перейдите: **Настройки → Администрирование → 1C WebClient**
3. Нажмите **«Добавить базу»**
4. Заполните:
   - **Название:** `Бухгалтерия предприятия`
   - **URL:** `https://192.168.1.100/buh/`
5. Сохраните

### Примеры заполнения

| Название | URL |
|----------|-----|
| Бухгалтерия | `https://192.168.1.100/buh/` |
| Зарплата и кадры | `https://192.168.1.100/zup/` |
| Управление торговлей | `https://192.168.1.101/ut/` |

---

## 🔧 Решение проблем

### ❌ Ошибка Mixed Content

**Причина:** 1С доступна по HTTP, а Nextcloud по HTTPS

**Решение:** Настройте HTTPS на сервере 1С

```bash
curl -kI https://192.168.1.100/buh/
# Должен вернуть: HTTP/2 200 OK
```

### ❌ CSP блокирует фрейм

**Причина:** Домен 1С не в белом списке

**Решение:** Отредактируйте `PageController.php`:

```php
$csp->addAllowedFrameDomain('https://192.168.1.100');
$csp->addAllowedScriptDomain('https://192.168.1.100');
```

### ❌ Самоподписанный сертификат

**Решение:** Откройте 1С напрямую в браузере и примите сертификат.

---

## 📁 Структура проекта

```
one_c_web_client/
├── appinfo/           # Метаданные приложения
├── lib/               # PHP классы
│   ├── AppInfo/
│   ├── Controller/
│   └── Settings/
├── templates/         # HTML шаблоны
├── js/                # JavaScript
├── css/               # Стили
├── l10n/              # Переводы
├── deploy.sh          # Скрипт установки
├── INSTALLATION_GUIDE.md  # Полная инструкция
└── QUICK_START_RU.md      # Быстрый старт
```

---

## 📖 Документация

- **[INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)** — Полное руководство по установке и настройке
- **[QUICK_START_RU.md](QUICK_START_RU.md)** — Быстрый старт за 5 минут
- **[DEPLOYMENT_PACKAGE.md](DEPLOYMENT_PACKAGE.md)** — Информация о пакете

---

## 🔒 Безопасность

- ✅ HTTPS на серверах 1С (обязательно)
- ✅ Content Security Policy (CSP)
- ✅ Проверка прав доступа
- ✅ Изоляция в iframe

---

## 📊 Статистика

- **Версия:** 1.0.0
- **Лицензия:** AGPL v3
- **Совместимость:** Nextcloud 31-32
- **Размер:** 36 KB
- **Время установки:** 2-5 минут

---

## 🤝 Поддержка

### Логи для диагностики

```bash
# Nextcloud
tail -f /path/to/nextcloud/data/nextcloud.log

# Apache
tail -f /var/log/apache2/error.log

# Nginx
tail -f /var/log/nginx/error.log
```

### Полезные команды

```bash
# Статус приложения
occ app:list | grep one_c_web_client

# Переустановка
occ app:disable one_c_web_client
occ app:remove one_c_web_client
occ app:install one_c_web_client

# Очистка кэша
occ maintenance:repair
```

---

## 📄 Лицензия

**AGPL v3** — GNU Affero General Public License

---

## 🎉 Ссылки

- **Репозиторий:** [github.com/smidttmn/one_c_web_client](https://github.com/smidttmn/one_c_web_client)
- **Релизы:** [Скачать последнюю версию](https://github.com/smidttmn/one_c_web_client/releases)
- **Issues:** [Сообщить о проблеме](https://github.com/smidttmn/one_c_web_client/issues)

---

**Разработано для интеграции 1С с Nextcloud** ❤️
