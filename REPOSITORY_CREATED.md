# one_c_web_client - Репозиторий создан! 🎉

## 📍 Расположение репозитория

**Локальный Git репозиторий:** `/home/smidt/nc1c/`

**Архив для установки:** `/home/smidt/one_c_web_client_deploy.tar.gz`

## 📁 Файлы готовы к копированию

```
/home/smidt/nc1c/
├── appinfo/              # Конфигурация приложения
├── lib/                  # PHP код
├── templates/            # Шаблоны
├── js/                   # JavaScript
├── img/                  # Изображения
├── l10n/                 # Переводы
├── README_INSTALLATION.md
├── QUICK_START.md
├── FTP_UPLOAD_INSTRUCTION.md
└── ...
```

## 📦 Для копирования на FTP

**Файл:** `one_c_web_client_deploy.tar.gz` (112 KB)

**Путь FTP:** `ftp://nas_home.local/nas/Обмен/`

### Быстрое копирование:

```bash
# Через curl (с паролем)
curl -T /home/smidt/one_c_web_client_deploy.tar.gz \
     ftp://nas_home.local/nas/Обмен/ \
     --user smidt_gw
```

### Или через файловый менеджер:

1. Откройте `ftp://nas_home.local/nas/Обмен/`
2. Логин: `smidt_gw`
3. Введите пароль
4. Перетащите файл `one_c_web_client_deploy.tar.gz`

## 📖 Документация

- **FTP_UPLOAD_INSTRUCTION.md** - Подробная инструкция по FTP
- **REPOSITORY_README.md** - Описание репозитория
- **README_INSTALLATION.md** - Установка на Nextcloud
- **QUICK_START.md** - Быстрый старт

## 🚀 Установка на Nextcloud

После копирования на FTP:

```bash
# 1. Скачайте архив на сервер Nextcloud
scp user@nas_home.local:/nas/Обмен/one_c_web_client_deploy.tar.gz /tmp/

# 2. Распакуйте
sudo tar -xzf /tmp/one_c_web_client_deploy.tar.gz -C /path/to/nextcloud/apps/
sudo mv /path/to/nextcloud/apps/nc1c /path/to/nextcloud/apps/one_c_web_client

# 3. Установите права
sudo chown -R www-data:www-data /path/to/nextcloud/apps/one_c_web_client

# 4. Установите приложение
sudo -u www-data php occ app:install one_c_web_client
sudo -u www-data php occ app:enable one_c_web_client
sudo -u www-data php occ maintenance:repair
```

## ✅ Готово!

**Репозиторий создан и готов к использованию!**

- ✅ Git репозиторий: `/home/smidt/nc1c/`
- ✅ Архив: `/home/smidt/one_c_web_client_deploy.tar.gz`
- ✅ Документация полная
- ✅ Совместимость: Nextcloud 31-32

---

**Версия:** 1.0.0 | **Дата:** Февраль 2026
