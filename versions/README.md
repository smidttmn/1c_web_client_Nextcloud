# 📚 УПРАВЛЕНИЕ ВЕРСИЯМИ one_c_web_client

**Проект:** Интеграция 1С с Nextcloud  
**Сервер:** cloud.smidt.keenetic.pro

---

## 📂 СТРУКТУРА ВЕРСИЙ:

```
versions/
├── v10.0.0/              # БАЗОВАЯ ВЕРСИЯ (историческая)
│   ├── app/
│   │   └── one_c_web_client_v3.tar.gz
│   ├── docs/
│   │   ├── README.md
│   │   ├── INSTALL.md
│   │   └── CHANGELOG.md
│   ├── scripts/
│   │   └── setup_apache_proxy_auto.sh
│   └── install.sh
│
├── v10.0.1/              # ✅ РАБОЧАЯ ВЕРСИЯ (РЕКОМЕНДУЕТСЯ)
│   ├── app/
│   │   └── one_c_web_client_v3.tar.gz
│   ├── docs/
│   │   ├── README.md
│   │   ├── INSTALL.md
│   │   └── CHANGELOG.md
│   ├── scripts/
│   │   └── setup_apache_proxy_auto.sh
│   └── install.sh
│
└── v10.0.2/              # Резерв (в разработке)
    └── README.md
```

---

## 🚀 БЫСТРЫЙ СТАРТ:

### Установка v10.0.1 (рекомендуется):

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./install.sh
```

---

## 📋 СЦЕНАРИИ ИСПОЛЬЗОВАНИЯ:

### Сценарий 1: Новая установка

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./install.sh
```

**Что делает:**
- ✅ Устанавливает приложение
- ✅ Настраивает Apache прокси (ПРАВИЛЬНО!)
- ✅ Добавляет серверы 1С (интерактивно)
- ✅ Проверяет установку

---

### Сценарий 2: Приложение есть, прокси нет

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./scripts/setup_apache_proxy_auto.sh
```

**Что делает:**
- ✅ Определяет конфигурацию Apache (SSL/NON_SSL)
- ✅ Настраивает прокси
- ✅ Перезапускает Apache

---

### Сценарий 3: Сломался прокси

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./scripts/setup_apache_proxy_auto.sh
```

**Что делает:**
- ✅ Удаляет старые настройки прокси
- ✅ Создаёт резервную копию
- ✅ Настраивает прокси заново
- ✅ Перезапускает Apache

---

## 📊 СРАВНЕНИЕ ВЕРСИЙ:

| Функция | v10.0.0 | v10.0.1 ✅ | v10.0.2 |
|---------|---------|-----------|---------|
| Авто-настройка прокси | ✅ | ✅ | ✅ |
| ProxyPass ДО исключений | ✅ | ✅ | ✅ |
| Исправлен слэш в ProxyPass | ❌ | ✅ | ✅ |
| Проверка авторизации | ❌ | ✅ | ✅ |
| Защита от прямых ссылок | ❌ | ✅ | ✅ |
| Совместимость с NC 30-34 | ❌ | ✅ | ✅ |

---

## 🔄 МИГРАЦИЯ МЕЖДУ ВЕРСИЯМИ:

### С v10.0.0 на v10.0.1:

```bash
# 1. Очистка
cd /home/smidt/nc1c
sudo ./reset_nextcloud.sh

# 2. Установка новой версии
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./install.sh
```

---

## 🛠️ ВОССТАНОВЛЕНИЕ:

### Если что-то пошло не так:

```bash
# 1. Очистка
cd /home/smidt/nc1c
sudo ./reset_nextcloud.sh

# 2. Возврат к рабочей версии
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./install.sh
```

---

## 📝 ДОКУМЕНТАЦИЯ ПО ВЕРСИЯМ:

- **v10.0.0:** `cat versions/v10.0.0/README.md`
- **v10.0.1:** `cat versions/v10.0.1/README.md` (РЕКОМЕНДУЕТСЯ)
- **v10.0.2:** `cat versions/v10.0.2/README.md` (в разработке)

---

## 🎯 ТЕКУЩАЯ ВЕРСИЯ:

**v10.0.1** - ИСПРАВЛЕННАЯ

**Исправления:**
- ✅ ProxyPass для путей 1С (слэш добавлен)
- ✅ Проверка авторизации пользователя
- ✅ Защита от прямых ссылок на прокси

**Установка:**
```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./install.sh
```

---

**Дата обновления:** 16 марта 2026  
**Статус:** ✅ ГОТОВО К УСТАНОВКЕ
