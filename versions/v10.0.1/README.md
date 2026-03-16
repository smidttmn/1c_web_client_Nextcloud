# one_c_web_client v10.0.1 - ИСПРАВЛЕННАЯ

**Дата выпуска:** 16 марта 2026  
**Статус:** ✅ РАБОЧАЯ ВЕРСИЯ (РЕКОМЕНДУЕТСЯ)

---

## 📦 Что входит:

- ✅ Приложение one_c_web_client_v3
- ✅ Исправленный ProxyPass (слэш перед путём 1С)
- ✅ Проверка авторизации пользователя
- ✅ Защита от прямых ссылок на прокси
- ✅ Авто-настройка Apache прокси (SSL + NON_SSL)

---

## 🚀 БЫСТРАЯ УСТАНОВКА:

### Сценарий 1: Новая установка

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./install.sh
```

**Следуйте инструкциям:**
1. `Продолжить установку? [Y/n]:` → **Y**
2. `Добавить сервер 1С сейчас? [Y/n]:` → **Y**
3. `Название базы:` → **БУХ СГТ**
4. `URL сервера 1С:` → **https://10.72.1.5/sgtbuh**
5. `Добавить ещё один сервер? [y/N]:` → **N**

---

### Сценарий 2: Приложение есть, прокси нет

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./scripts/setup_apache_proxy_auto.sh
```

---

### Сценарий 3: Сломался прокси

```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./scripts/setup_apache_proxy_auto.sh
```

---

## 🔧 Исправления в v10.0.1:

### 1. Исправлен ProxyPass для путей 1С:

**БЫЛО (ошибка):**
```apache
ProxyPass sgtbuh https://10.72.1.5sgtbuh
```

**СТАЛО (правильно):**
```apache
ProxyPass /sgtbuh https://10.72.1.5/sgtbuh
ProxyPassReverse /sgtbuh https://10.72.1.5/sgtbuh
```

### 2. Добавлена проверка авторизации:

```php
// ProxyController.php
$user = $this->userSession->getUser();
if ($user === null) {
    return new DataDisplayResponse(
        'Access denied. Please login to Nextcloud first.', 
        Http::STATUS_UNAUTHORIZED
    );
}
```

### 3. Правильная конфигурация Apache:

```apache
# ProxyPass ДО всех исключений
ProxyPass /one_c_web_client_v3 https://10.72.1.5/
ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1

# Пути 1С (со слэшем!)
ProxyPass /sgtbuh https://10.72.1.5/sgtbuh
ProxyPass /zupnew https://10.72.1.5/zupnew

# ИСКЛЮЧЕНИЯ (после!)
ProxyPass /core !
ProxyPass /apps !
```

---

## 📋 Структура версии:

```
versions/v10.0.1/
├── app/
│   └── one_c_web_client_v3.tar.gz  # Архив приложения
├── docs/
│   ├── README.md                    # Этот файл
│   ├── INSTALL.md                   # Инструкция
│   └── CHANGELOG.md                 # Изменения
├── scripts/
│   └── setup_apache_proxy_auto.sh   # Настройка прокси
└── install.sh                       # Установщик
```

---

## ✅ Проверка после установки:

1. Откройте: `https://cloud.smidt.keenetic.pro`
2. Нажмите `Ctrl + Shift + R`
3. Найдите иконку "1C WebClient" в меню
4. Нажмите на кнопку базы 1С

**1С должна открыться!**

---

## 🆘 Устранение проблем:

### Ошибка 404:
```bash
cd /home/smidt/nc1c/versions/v10.0.1
sudo ./scripts/setup_apache_proxy_auto.sh
```

### Ошибка 502:
```bash
curl -k https://10.72.1.5/sgtbuh/
```

---

**Предыдущая версия:** v10.0.0  
**Следующая версия:** v10.0.2 (в разработке)
