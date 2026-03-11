# ✅ one_c_web_client_v3 - ГОТОВО К УСТАНОВКЕ

## 📦 Что создано

### Установочные файлы

| Файл | Размер | Назначение |
|------|--------|------------|
| **install_interactive.sh** | 23 KB | 🚀 Интерактивный скрипт установки |
| **one_c_web_client_v3_deploy.tar.gz** | 13 KB | 📦 Архив приложения |
| **one_c_web_client_v3_full.tar.gz** | 25 KB | 📦 Полный пакет (скрипт + приложение) |

### Документация

| Файл | Описание |
|------|----------|
| **INSTALLER_GUIDE.md** | 📖 Подробное описание установщика |
| **INSTALL_GUIDE_v3.md** | 📖 Полная инструкция по установке |
| **QUICK_START_v3.md** | 📖 Быстрый старт (3 команды) |
| **README_VERSIONS.md** | 📖 Описание всех версий приложения |

---

## 🚀 Быстрая установка

### Вариант 1: Интерактивный скрипт (рекомендуется)

```bash
# Перейдите в директорию
cd /home/smidt/nc1c

# Запустите установщик от root
sudo ./install_interactive.sh
```

**Что сделает скрипт:**
1. ⚙️ Автоопределит Nextcloud, Apache, SSL
2. 📝 Запросит настройки в интерактивном режиме
3. 📦 Установит приложение
4. 🔧 Настроит Apache (безопасно дополнит конфиг)
5. ✅ Проверит установку

### Вариант 2: Ручная установка

```bash
# Распакуйте полный пакет
tar -xzf one_c_web_client_v3_full.tar.gz

# Запустите скрипт
sudo ./install_interactive.sh
```

### Вариант 3: Копирование на сервер Nextcloud

```bash
# На локальном компьютере
cd /home/smidt/nc1c

# Скопируйте на сервер Nextcloud
scp one_c_web_client_v3_full.tar.gz user@nextcloud-server:/tmp/

# На сервере Nextcloud
ssh user@nextcloud-server
cd /tmp
tar -xzf one_c_web_client_v3_full.tar.gz
sudo ./install_interactive.sh
```

---

## 📋 Что спросит установщик

1. **Путь к Nextcloud** - обычно `/var/www/nextcloud` (определяется автоматически)
2. **Конфиг Apache** - обычно `/etc/apache2/sites-available/nextcloud.conf`
3. **Доменное имя** - например, `cloud.example.com`
4. **SSL сертификаты** - если Let's Encrypt, подставит автоматически
5. **1С сервер** - например, `https://10.72.1.5`
6. **Базы 1С** - идентификаторы баз (buh, zup, ut и т.д.)
7. **Версия приложения** - выберите v3 (рекомендуется)

---

## ✅ Проверка после установки

```bash
# Проверьте статус приложения
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c

# Должно вывести:
# one_c_web_client_v3: 3.1.0
```

---

## 🎯 Использование

### 1. Откройте админ-панель

```
https://your-nextcloud-domain/index.php/settings/admin/one_c_web_client_v3
```

### 2. Добавьте базы 1С

Пример:
- **Название**: Бухгалтерия
- **Идентификатор**: buh
- **URL**: https://10.72.1.5/buh

### 3. Проверьте работу

```
https://your-nextcloud-domain/index.php/apps/one_c_web_client_v3/
```

---

## 🔍 Диагностика

### Логи установщика

```bash
cat /tmp/one_c_install_*.log
```

### Логи Nextcloud

```bash
sudo -u www-data php /var/www/nextcloud/occ log:manage --level debug
tail -f /var/www/nextcloud/data/nextcloud.log
```

### Проверка Apache

```bash
apache2ctl configtest
a2query -m proxy
a2query -m proxy_http
```

---

## 📁 Структура проекта

```
/home/smidt/nc1c/
├── install_interactive.sh          # ⭐ Интерактивный установщик
├── one_c_web_client_v3_deploy.tar.gz  # 📦 Архив приложения
├── one_c_web_client_v3_full.tar.gz    # 📦 Полный пакет
│
├── one_c_web_client_v3_clean/      # 📂 Исходники приложения v3
│   ├── appinfo/
│   │   ├── info.xml
│   │   └── routes.php
│   ├── lib/
│   │   ├── Controller/
│   │   └── Settings/
│   ├── templates/
│   ├── js/
│   └── l10n/
│
├── INSTALLER_GUIDE.md              # 📖 Описание установщика
├── INSTALL_GUIDE_v3.md             # 📖 Инструкция по установке
├── QUICK_START_v3.md               # 📖 Быстрый старт
├── README_VERSIONS.md              # 📖 Описание версий
│
└── ... (другие версии и архивы)
```

---

## 🛡️ Безопасность

Установщик:
- ✅ Создает резервные копии конфига Apache
- ✅ Проверяет синтаксис перед применением
- ✅ Устанавливает минимальные права (www-data)
- ✅ Включает SSL Proxy для безопасного соединения
- ✅ Логирует все действия

---

## 📞 Поддержка

При проблемах:

1. Проверьте логи: `/tmp/one_c_install_*.log`
2. Запустите диагностику:
   ```bash
   sudo -u www-data php /var/www/nextcloud/occ app:list
   apache2ctl configtest
   ```
3. Изучите документацию: `INSTALLER_GUIDE.md`

---

## 📄 Лицензия

AGPL v3

---

**Версия**: 3.1.0  
**Дата**: Март 2026  
**Nextcloud**: 31-32  
**PHP**: 7.4+

---

## ✨ Готово!

Все файлы готовы к установке. Запустите:

```bash
sudo ./install_interactive.sh
```
