# one_c_web_client Repository

## 📦 Описание

Приложение для интеграции 1С с Nextcloud. Позволяет открывать базы 1С прямо в интерфейсе Nextcloud через HTTPS.

## 🚀 Быстрый старт

### Установка из архива

```bash
# Скопируйте архив на сервер Nextcloud
scp one_c_web_client_deploy.tar.gz user@nextcloud:/tmp/

# Распакуйте
sudo tar -xzf /tmp/one_c_web_client_deploy.tar.gz -C /path/to/nextcloud/apps/
sudo mv /path/to/nextcloud/apps/nc1c /path/to/nextcloud/apps/one_c_web_client

# Установите права
sudo chown -R www-data:www-data /path/to/nextcloud/apps/one_c_web_client

# Установите приложение
sudo -u www-data php occ app:install one_c_web_client
sudo -u www-data php occ app:enable one_c_web_client
sudo -u www-data php occ maintenance:repair
```

### Установка из Git

```bash
# Клонируйте репозиторий в apps Nextcloud
cd /path/to/nextcloud/apps/
sudo git clone /path/to/repo/one_c_web_client.git

# Установите права
sudo chown -R www-data:www-data one_c_web_client

# Установите приложение
sudo -u www-data php occ app:install one_c_web_client
```

## 📋 Требования

- **Nextcloud:** 31-32 версии
- **PHP:** 8.0+
- **1С:** HTTPS (обязательно!)

## 📖 Документация

- [QUICK_START.md](./QUICK_START.md) - Быстрый старт
- [README_INSTALLATION.md](./README_INSTALLATION.md) - Полная инструкция
- [SMB_DEPLOYMENT.md](./SMB_DEPLOYMENT.md) - Копирование на SMB/FTP
- [DEPLOYMENT_STATUS.md](./DEPLOYMENT_STATUS.md) - Статус совместимости

## 🔧 Настройка

1. Откройте Nextcloud
2. Настройки → Администрирование → **1C WebClient**
3. Добавьте базы 1С:
   - Название: `Бухгалтерия`
   - URL: `https://10.72.1.5/sgtbuh/`

## 📞 Поддержка

При проблемах смотрите:
- Логи Nextcloud: `data/nextcloud.log`
- Логи Apache: `/var/log/apache2/error.log`
- Консоль браузера (F12)

## 📄 Лицензия

AGPL v3

---

**Версия:** 1.0.0 | **Дата:** Февраль 2026
