# one_c_web_client_v3 для GitHub

**Интеграция 1С:Предприятие с Nextcloud**

[![Nextcloud](https://img.shields.io/badge/Nextcloud-31--32-blue)](https://nextcloud.com)
[![License](https://img.shields.io/badge/License-AGPLv3-green)](LICENSE)

---

## 📦 Быстрый старт

### 1. Скачайте последнюю версию

Перейдите в [Releases](https://github.com/YOUR_USERNAME/one_c_web_client_v3/releases) и скачайте последнюю версию.

### 2. Распакуйте на сервер Nextcloud

```bash
cd /tmp
tar -xzf one_c_web_client_v3.tar.gz
cd v3
```

### 3. Запустите установщик

```bash
sudo ./install.sh
```

### 4. Настройте базы 1С

Откройте админ-панель Nextcloud и добавьте базы 1С через интерфейс.

---

## 📖 Документация

- [README.md](README.md) - полная документация
- [QUICK_START.md](QUICK_START.md) - быстрый старт
- [INSTALL.md](INSTALL.md) - подробная инструкция по установке

---

## 🔧 Требования

- Nextcloud 31 или 32
- Apache с mod_proxy, mod_proxy_http, mod_rewrite, mod_headers
- PHP 7.4+
- HTTPS на сервере

---

## 🚀 Возможности

- ✅ Динамический прокси для неограниченного количества баз 1С
- ✅ Защита от неавторизованного доступа
- ✅ Админ-панель для настройки баз
- ✅ Автоматический установщик
- ✅ Поддержка Nextcloud 32

---

## 📝 Лицензия

AGPL v3

---

## ⚠️ Важно

Этот репозиторий НЕ содержит личных данных:
- Нет реальных URL серверов
- Нет IP-адресов
- Нет имён пользователей
- Нет паролей

Все примеры в документации используют обобщённые значения:
- `your-nextcloud-domain` вместо реального домена
- `10.72.1.5` как пример IP сервера 1С
- `buh` как пример идентификатора базы

---

**Версия:** 3.0.0  
**Дата:** Март 2026
