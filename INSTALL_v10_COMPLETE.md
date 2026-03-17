# 🚀 ИНСТРУКЦИЯ ПО УСТАНОВКЕ v10.0.0-COMPLETE

**Версия:** 10.0.0-COMPLETE  
**Дата:** 16 марта 2026  
**Статус:** ✅ РАБОЧАЯ ВЕРСИЯ С АВТО-НАСТРОЙКОЙ ПРОКСИ

---

## 📦 ЧТО ВХОДИТ:

- ✅ Приложение one_c_web_client_v3
- ✅ **install.sh** - установщик с авто-настройкой прокси
- ✅ **setup_apache_proxy_auto.sh** - быстрая настройка прокси
- ✅ Полная документация

---

## 🎯 БЫСТРАЯ УСТАНОВКА (3 КОМАНДЫ):

```bash
# 1. Перейдите в директорию версии
cd /home/smidt/nc1c/versions/v10.0.0-complete

# 2. Запустите установщик
sudo ./scripts/install.sh

# 3. Следуйте инструкциям:
#    - Нажмите Y (продолжить)
#    - Нажмите Y (добавить сервер 1С)
#    - Введите: БУХ СГТ
#    - Введите: https://10.72.1.5/sgtbuh
#    - Нажмите N (больше серверов нет)
```

---

## 📋 ПОДРОБНАЯ ИНСТРУКЦИЯ:

### Шаг 1: Подготовка

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
```

---

### Шаг 2: Запуск установщика

```bash
sudo ./scripts/install.sh
```

---

### Шаг 3: Интерактивная установка

**Вопрос 1:** Продолжить установку? [Y/n]
```
→ Нажмите Y
```

**Вопрос 2:** Добавить сервер 1С сейчас? [Y/n]
```
→ Нажмите Y
```

**Вопрос 3:** Название базы
```
→ Введите: БУХ СГТ
```

**Вопрос 4:** URL сервера 1С
```
→ Введите: https://10.72.1.5/sgtbuh
```

**Вопрос 5:** Добавить ещё один сервер? [y/N]
```
→ Нажмите N
```

---

### Шаг 4: Автоматическая настройка

Установщик автоматически:
- ✅ Найдёт Nextcloud
- ✅ Найдёт конфигурацию Apache (SSL или NON_SSL)
- ✅ Проверит модули Apache
- ✅ Установит приложение
- ✅ **Настроит Apache прокси ПРАВИЛЬНО**
- ✅ Проверит синтаксис Apache
- ✅ Перезапустит Apache

---

### Шаг 5: Проверка работы

1. Откройте: `https://cloud.smidt.keenetic.pro`
2. Нажмите `Ctrl + Shift + R`
3. Найдите иконку "1C WebClient" в меню
4. Нажмите на кнопку базы 1С

**1С должна открыться!**

---

## 🔧 ДРУГИЕ СЦЕНАРИИ:

### Приложение есть, прокси нет:

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/setup_apache_proxy_auto.sh
```

### Сломался прокси:

```bash
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/setup_apache_proxy_auto.sh
```

### Очистка и переустановка:

```bash
# Очистка
cd /home/smidt/nc1c
sudo ./reset_nextcloud.sh

# Установка заново
cd /home/smidt/nc1c/versions/v10.0.0-complete
sudo ./scripts/install.sh
```

---

## ✅ ЧТО ИСПРАВЛЕНО В ЭТОЙ ВЕРСИИ:

### 1. Автоматическая настройка прокси:

```bash
# Установщик сам настраивает Apache:
# - Определяет тип конфигурации (SSL или NON_SSL)
# - Добавляет ProxyPass ДО всех исключений
# - Добавляет ProxyPassMatch для путей
# - Добавляет mod_substitute для переписывания URL
```

### 2. Правильная конфигурация Apache:

```apache
# ProxyPass ДО исключений
ProxyPass /one_c_web_client_v3 https://10.72.1.5/
ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1

# Пути 1С
ProxyPass /sgtbuh https://10.72.1.5/sgtbuh
ProxyPass /zupnew https://10.72.1.5/zupnew

# ИСКЛЮЧЕНИЯ (после!)
ProxyPass /core !
ProxyPass /apps !
```

### 3. Универсальность:

- ✅ SSL конфигурация (порт 443)
- ✅ NON_SSL конфигурация (порт 80)
- ✅ Автоматическое определение

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

## 📚 ДОПОЛНИТЕЛЬНАЯ ДОКУМЕНТАЦИЯ:

- `versions/README.md` - управление версиями
- `versions/v10.0.0-complete/README.md` - документация версии
- `/home/smidt/nc1c/АВТОМАТИЧЕСКАЯ_НАСТРОЙКА_ПРОКСИ.md` - подробная инструкция

---

**Версия:** 10.0.0-COMPLETE  
**Статус:** ✅ ГОТОВО К УСТАНОВКЕ
