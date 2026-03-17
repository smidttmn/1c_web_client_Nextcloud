# one_c_web_client v10.0.0-COMPLETE

**Дата выпуска:** 16 марта 2026  
**Статус:** ✅ РАБОЧАЯ ВЕРСИЯ С АВТО-НАСТРОЙКОЙ ПРОКСИ

---

## 📦 ЧТО ВХОДИТ:

- ✅ Приложение one_c_web_client_v3
- ✅ **install.sh** - установщик с авто-настройкой прокси
- ✅ **setup_apache_proxy_auto.sh** - быстрая настройка прокси
- ✅ Полная документация

---

## 🚀 БЫСТРАЯ УСТАНОВКА:

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/install.sh
```

---

## 📋 СЦЕНАРИИ ИСПОЛЬЗОВАНИЯ:

### Сценарий 1: Новая установка

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/install.sh
```

**Что делает:**
- ✅ Устанавливает приложение
- ✅ **Автоматически настраивает Apache прокси**
- ✅ Определяет конфигурацию (SSL или NON_SSL)
- ✅ Добавляет ProxyPass **ДО** всех исключений
- ✅ Создаёт резервную копию

---

### Сценарий 2: Приложение есть, прокси нет

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/setup_apache_proxy_auto.sh
```

**Что делает:**
- ✅ Автоматически определяет конфигурацию Apache
- ✅ Получает сервер 1С из Nextcloud
- ✅ Настраивает прокси ПРАВИЛЬНО
- ✅ Перезапускает Apache

---

### Сценарий 3: Сломался прокси

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/setup_apache_proxy_auto.sh
```

**Что делает:**
- ✅ Удаляет старые настройки
- ✅ Создаёт резервную копию
- ✅ Настраивает прокси заново
- ✅ Перезапускает Apache

---

## 🔧 ОСОБЕННОСТИ ВЕРСИИ:

### 1. Автоматическая настройка прокси:

```bash
# Установщик сам:
# - Находит конфигурацию Apache (SSL или NON_SSL)
# - Добавляет ProxyPass ДО всех исключений
# - Добавляет ProxyPassMatch для путей
# - Добавляет mod_substitute для переписывания URL
# - Отключает AllowOverride для работы прокси
```

### 2. Правильная конфигурация Apache:

```apache
# SSL Proxy Settings
SSLProxyEngine on
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off

# ProxyPass ДО исключений
ProxyPass /one_c_web_client_v3 https://10.72.1.5/ retry=0 timeout=60
ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1

# Пути 1С
ProxyPass /sgtbuh https://10.72.1.5/sgtbuh
ProxyPass /zupnew https://10.72.1.5/zupnew

# ИСКЛЮЧЕНИЯ (после!)
ProxyPass /core !
ProxyPass /apps !
```

### 3. Универсальность:

- ✅ **SSL конфигурация** (порт 443) - `nextcloud-le-ssl.conf`
- ✅ **NON_SSL конфигурация** (порт 80) - `nextcloud.conf`
- ✅ **Автоматическое определение** типа конфигурации

---

## 📁 СТРУКТУРА ВЕРСИИ:

```
versions/v10.0.0-complete/
├── app/
│   └── one_c_web_client_v3.tar.gz  # Архив приложения
├── scripts/
│   ├── install.sh                   # Установщик
│   └── setup_apache_proxy_auto.sh   # Настройка прокси
├── docs/
│   └── README.md                    # Этот файл
└── README.md                        # Краткая инструкция
```

---

## ✅ ПРОВЕРКА ПОСЛЕ УСТАНОВКИ:

1. Откройте: `https://cloud.smidt.keenetic.pro`
2. Нажмите `Ctrl + Shift + R`
3. Найдите иконку "1C WebClient" в меню
4. Нажмите на кнопку базы 1С

**1С должна открыться!**

---

## 🆘 УСТРАНЕНИЕ ПРОБЛЕМ:

### Ошибка 404:
```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/setup_apache_proxy_auto.sh
```

### Ошибка 502:
```bash
curl -k https://10.72.1.5/sgtbuh/
```

### Проверка состояния:
```bash
sudo -u www-data php /var/www/nextcloud/occ app:list | grep one_c
```

---

## 📚 ПОЛНАЯ ДОКУМЕНТАЦИЯ:

См. файлы в `/home/smidt/nc1c/`:
- `АВТОМАТИЧЕСКАЯ_НАСТРОЙКА_ПРОКСИ.md`
- `БЫСТРЫЙ_СТАРТ_ПРОКСИ.md`
- `АВТО_НАСТРОЙКА_ЗАВЕРШЕНО.md`

---

**Версия:** 10.0.0-COMPLETE  
**Статус:** ✅ ГОТОВО К УСТАНОВКЕ
