# 🧪 Установка на тестовый сервер (cloud.smidt.keenetic.pro)

**Ветка:** `feature/proxy-with-rewrite`  
**Сервер:** 10.1.72.70 (cloud.smidt.keenetic.pro)  
**Nextcloud:** Чистая установка

---

## 🚀 БЫСТРАЯ УСТАНОВКА

**Подключитесь к серверу по SSH:**
```bash
ssh root@10.1.72.70
# или по домену:
ssh root@cloud.smidt.keenetic.pro
```

**Скопируйте и запустите скрипт:**
```bash
cd /tmp
wget https://raw.githubusercontent.com/smidttmn/one_c_web_client/feature/proxy-with-rewrite/install_test.sh
chmod +x install_test.sh
sudo ./install_test.sh
```

**ИЛИ через git:**
```bash
cd /tmp
git clone -b feature/proxy-with-rewrite https://github.com/smidttmn/one_c_web_client.git
cd one_c_web_client
chmod +x install_test.sh
sudo ./install_test.sh
```

---

## 📋 ЧТО ДЕЛАЕТ СКРИПТ

1. ✅ Проверяет зависимости (git, Nextcloud)
2. ✅ Клонирует репозиторий из GitHub
3. ✅ Находит приложение в репозитории
4. ✅ Копирует в `/var/www/html/nextcloud/apps/`
5. ✅ Устанавливает права (www-data:www-data)
6. ✅ Устанавливает приложение через `occ app:install`
7. ✅ Очищает кэш (maintenance:repair, memcache:clear)
8. ✅ Проверяет установку
9. ✅ Перезапускает Apache

---

## ✅ ПРОВЕРКА ПОСЛЕ УСТАНОВКИ

### 1. Проверьте приложение

```bash
sudo -u www-data php occ app:list | grep one_c
```

Должно быть:
```
one_c_web_client_v3: 3.2.3
```

### 2. Откройте в браузере

**Админка Nextcloud:**
```
https://cloud.smidt.keenetic.pro/index.php/settings/admin
```

**Настройки приложения:**
```
https://cloud.smidt.keenetic.pro/index.php/settings/admin/one_c_web_client_v3
```

**Клиентская часть:**
```
https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client_v3/
```

### 3. Проверьте логи

```bash
tail -f /var/www/html/nextcloud/data/nextcloud.log
```

**Не должно быть ошибок 500!**

---

## 🔧 НАСТРОЙКА БАЗ 1С

### 1. Откройте админ-панель

Перейдите по адресу:
```
https://cloud.smidt.keenetic.pro/index.php/settings/admin/one_c_web_client_v3
```

### 2. Добавьте базу 1С

- **Название:** Бухгалтерия (или другое)
- **URL:** https://10.72.1.5/one_c_web_client_v3/ (или ваш сервер 1С)

### 3. Проверьте работу

Откройте:
```
https://cloud.smidt.keenetic.pro/index.php/apps/one_c_web_client_v3/
```

Должна появиться кнопка с названием базы 1С.

---

## 🐛 РЕШЕНИЕ ПРОБЛЕМ

### Ошибка 500

**Проверьте логи:**
```bash
sudo -u www-data php occ log:read | tail -50
```

**Очистите кэш:**
```bash
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ memcache:clear
systemctl restart php8.1-fpm
systemctl restart apache2
```

### Приложение не найдено

**Проверьте наличие файлов:**
```bash
ls -la /var/www/html/nextcloud/apps/one_c_web_client_v3/
```

**Проверьте права:**
```bash
chown -R www-data:www-data /var/www/html/nextcloud/apps/one_c_web_client_v3
chmod -R 755 /var/www/html/nextcloud/apps/one_c_web_client_v3
```

### Ошибка CSP (Content Security Policy)

**Проверьте конфиг Apache:**
```bash
grep -A10 "Content-Security-Policy" /etc/apache2/sites-available/nextcloud.conf
```

**Должно быть:**
```apache
Header always set Content-Security-Policy "frame-ancestors 'self'; frame-src *; ..."
```

---

## 📊 АРХИТЕКТУРА ПРИЛОЖЕНИЯ С ПРОКСИ

```
┌─────────────────────┐         ┌──────────────────────┐         ┌─────────────┐
│   Браузер клиента   │ ──────> │   Nextcloud (HTTPS)  │ ──────> │  Сервер 1С  │
│                     │ <────── │   (проксирует URL)   │ <────── │  (HTTPS)    │
└─────────────────────┘         └──────────────────────┘         └─────────────┘
         │                                │                              │
         │                                │                              │
    cloud.smidt.                   one_c_web_client_v3           10.72.1.5
     keenetic.pro
```

**Принцип работы:**
1. Клиент открывает Nextcloud по HTTPS
2. Nextcloud проксирует запросы к 1С
3. Прокси переписывает URL в HTML/JS
4. Клиент получает доступ к 1С через Nextcloud

---

## 📋 ТРЕБОВАНИЯ

| Компонент | Требование | Статус |
|-----------|------------|--------|
| Nextcloud | 30-32 | ✅ |
| PHP | 8.0-8.3 | ✅ |
| Apache | mod_proxy, mod_proxy_http, mod_headers, mod_rewrite | ✅ |
| HTTPS | Обязательно | ✅ |
| Доступ к 1С | Сервер 1С должен быть доступен из Nextcloud | ✅ |

---

## 🔍 ДИАГНОСТИКА

### Полная информация о системе

```bash
echo "=== Версия Nextcloud ==="
sudo -u www-data php occ status

echo "=== Версия PHP ==="
php -v

echo "=== Модули Apache ==="
a2query -m proxy proxy_http headers rewrite ssl

echo "=== Статус приложений ==="
sudo -u www-data php occ app:list --enabled

echo "=== Логи Nextcloud ==="
sudo -u www-data php occ log:read | tail -50

echo "=== Логи Apache ==="
tail -50 /var/log/apache2/error.log
```

---

## 📞 ЕСЛИ ЧТО-ТО ПОШЛО НЕ ТАК

**Отправьте разработчику:**

1. **Лог Nextcloud:**
   ```bash
   sudo -u www-data php occ log:read > /tmp/nc_log.txt
   ```

2. **Лог Apache:**
   ```bash
   tail -100 /var/log/apache2/error.log > /tmp/apache_log.txt
   ```

3. **Информацию о приложении:**
   ```bash
   sudo -u www-data php occ app:list | grep one_c > /tmp/app_info.txt
   ```

4. **Версию PHP и Apache:**
   ```bash
   php -v && apache2 -v > /tmp/server_info.txt
   ```

---

**Готово к установке!** 🎉
