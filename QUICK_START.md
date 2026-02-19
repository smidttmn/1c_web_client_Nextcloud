# one_c_web_client - Краткая инструкция по развертыванию

## 📦 Что в архиве

- `one_c_web_client/` - Приложение для Nextcloud
- `README_INSTALLATION.md` - Полная инструкция
- `DEPLOYMENT_STATUS.md` - Статус и совместимость

## 🚀 Быстрый старт

### 1. Скопируйте на сервер Nextcloud

```bash
# Распакуйте архив в apps Nextcloud
sudo tar -xzf one_c_web_client_deploy.tar.gz -C /path/to/nextcloud/apps/
sudo mv /path/to/nextcloud/apps/nc1c /path/to/nextcloud/apps/one_c_web_client
```

### 2. Установите права

```bash
sudo chown -R www-data:www-data /path/to/nextcloud/apps/one_c_web_client
```

### 3. Установите приложение

```bash
sudo -u www-data php /path/to/nextcloud/occ app:install one_c_web_client
sudo -u www-data php /path/to/nextcloud/occ app:enable one_c_web_client
sudo -u www-data php /path/to/nextcloud/occ maintenance:repair
```

### 4. Настройте базы 1С

1. Войдите в Nextcloud как администратор
2. Настройки → Администрирование → **1C WebClient**
3. Добавьте базы:
   - `СГТ Бухгалтерия` - `https://10.72.1.5/sgtbuh/`
   - `СГТ Кадры` - `https://10.72.1.5/zupnew/`

## ✅ Требования

- **Nextcloud:** Версия 31-32
- **1С:** Обязательно HTTPS!
- **Доступ:** Nextcloud → 1С серверы

## 🔧 Если проблемы

### Mixed Content ошибка
- Настройте HTTPS на 1С
- Или используйте Apache прокси (см. полную инструкцию)

### CSP блокирует
- Добавьте домен в `PageController.php`:
  ```php
  $csp->addAllowedFrameDomain('https://your-1c.com');
  ```

### Сертификат не доверяется
- Откройте 1С напрямую в браузере
- Примите сертификат
- Попробуйте снова в Nextcloud

## 📞 Поддержка

Смотрите полную инструкцию: `README_INSTALLATION.md`

---
**Версия:** 1.0.0 | **Дата:** Февраль 2026
