# 🛡️ install_safe_ssl.sh - УЛУЧШЕННАЯ ВЕРСИЯ

## ✅ Что исправлено по рекомендациям DeepSeek

### 1. Надёжное позиционирование директив в Apache

**БЫЛО:**
```bash
# Вставка после SSLProxyEngine on
sed -i '/SSLProxyEngine on/a ...' "$config"
```

**СТАЛО:**
```bash
# Поиск конкретного VirtualHost *:443 через awk
vhost_info=$(awk '
/<VirtualHost.*:443>/ { in_vhost=1; vhost_start=NR; next }
in_vhost && /<\/VirtualHost>/ {
    vhost_end = NR
    if (has_servername > 0) {
        print vhost_start ":" vhost_end ":" has_servername
        exit
    }
}
in_vhost && /ServerName|ServerAlias/ { has_servername = NR }
' "$APACHE_CONFIG")

# Вставка перед закрывающим </VirtualHost>
sed -i "${line_before_end}r $directives_file" "$temp_config"
```

**Преимущества:**
- ✅ Директивы вставляются именно в нужный VirtualHost
- ✅ Работает с несколькими VirtualHost в конфиге
- ✅ Не зависит от наличия SSLProxyEngine on

---

### 2. Переменная ONE_C_SERVER_WS определена до использования

**БЫЛО:**
```bash
# В блоке вставки используется переменная
ProxyPass /OneClick/ws $ONE_C_SERVER_WS/OneClick/ws
# Но она не определена!
```

**СТАЛО:**
```bash
# Сразу после ввода 1С сервера
ONE_C_SERVER_WS=$(echo "$ONE_C_SERVER" | sed 's|https://|ws://|; s|http://|ws://|')
print_info "WebSocket URL: $ONE_C_SERVER_WS"
```

**Преимущества:**
- ✅ WebSocket прокси будет работать корректно
- ✅ Переменная определена до использования в sed

---

### 3. Graceful reload вместо restart

**БЫЛО:**
```bash
systemctl restart apache2  # Обрывает все соединения
```

**СТАЛО:**
```bash
apache2ctl graceful  # Плавная перезагрузка без разрыва соединений
# или
systemctl reload apache2
```

**Преимущества:**
- ✅ Не обрывает активные подключения
- ✅ Минимизирует прерывания работы

---

### 4. Проверка выбранного конфига на соответствие домену

**ДОБАВЛЕНО:**
```bash
# Показываем домены из конфига
domains=$(get_domains_from_config "$config")
if [ -n "$domains" ]; then
    echo "   Домены: $domains"
fi

# Проверка после установки
if grep -q "ServerName.*$domain\|ServerAlias.*$domain" "$config"; then
    return 0
fi
```

**Преимущества:**
- ✅ Пользователь видит какие домены в конфиге
- ✅ Меньше шансов выбрать неправильный конфиг

---

### 5. Улучшенное резервное копирование

**ДОБАВЛЕНО:**
```bash
backup_config() {
    local backup_dir="/tmp/one_c_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Копируем конфиг
    cp "$config" "$backup_dir/apache_config.backup"
    
    # Копируем симлинк из sites-enabled
    cp -P "$enabled_link" "$backup_dir/apache_symlink.backup" 2>/dev/null || true
    
    # Копируем приложение если есть
    cp -r "$app_dir" "$backup_dir/app_backup" 2>/dev/null || true
    
    echo "$backup_dir"
}

restore_backup() {
    # Восстановление при ошибке
    cp "$backup_dir/apache_config.backup" "$config"
    apache2ctl graceful
}
```

**Преимущества:**
- ✅ Сохраняется несколько копий (конфиг, симлинк, приложение)
- ✅ Автоматическое восстановление при ошибке

---

### 6. Проверка синтаксиса перед применением

**ДОБАВЛЕНО:**
```bash
# Проверяем синтаксис временного конфига
if apache2ctl -t -f "$temp_config" 2>&1 | grep -q "Syntax OK"; then
    cp "$temp_config" "$APACHE_CONFIG"
else
    # Восстанавливаем резервную копию
    restore_backup "$backup_dir" "$APACHE_CONFIG"
    return 1
fi
```

**Преимущества:**
- ✅ Конфиг проверяется ДО записи
- ✅ При ошибке - автоматический откат

---

### 7. Интерактивный выбор конфига

**ДОБАВЛЕНО:**
```bash
# Показываем все найденные конфиги
echo "Найдено конфигов: ${#configs[@]}"
for i in "${!configs[@]}"; do
    echo "   $i)) ${configs[$i]}"
    domains=$(get_domains_from_config "${configs[$i]}")
    if [ -n "$domains" ]; then
        echo "      Домены: $domains"
    fi
done
echo "   0) Указать свой путь"
```

**Преимущества:**
- ✅ Пользователь видит все варианты
- ✅ Можно выбрать свой путь

---

### 8. Проверка наличия модулей

**ДОБАВЛЕНО:**
```bash
check_apache_modules() {
    local required_modules=("proxy" "proxy_http" "proxy_wstunnel" "headers" "rewrite" "ssl")
    local missing=()
    
    for module in "${required_modules[@]}"; do
        if ! a2query -m "$module" 2>/dev/null; then
            missing+=("$module")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "${missing[@]}"
        return 1
    fi
    return 0
}

# После включения
a2enmod proxy proxy_http proxy_wstunnel headers rewrite ssl
missing_modules=$(check_apache_modules)
if [ $? -eq 1 ]; then
    print_warning "Не удалось включить модули: $missing_modules"
fi
```

**Преимущества:**
- ✅ Проверка что модули действительно включены
- ✅ Предупреждение если что-то не включилось

---

### 9. Отдельный файл для директив 1С

**ДОБАВЛЕНО:**
```bash
# Создаем файл с директивами
directives_file=$(mktemp)
cat > "$directives_file" << EOF
    # ===================================================================
    # one_c_web_client_v3 - Прокси для 1С
    # ===================================================================
    
    SSLProxyEngine on
    # ... остальные директивы ...
EOF

# Вставляем перед </VirtualHost>
sed -i "${line_before_end}r $directives_file" "$temp_config"
```

**Преимущества:**
- ✅ Чёткая структура
- ✅ Комментарии для понимания
- ✅ Легко найти и отредактировать

---

### 10. Проверка на дублирование настроек

**ДОБАВЛЕНО:**
```bash
if grep -q "ProxyPass.*one_c" "$APACHE_CONFIG" 2>/dev/null; then
    print_warning "Настройки one_c_web_client уже найдены в конфиге"
    read -p "Продолжить и добавить ещё раз? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return 1
    fi
fi
```

**Преимущества:**
- ✅ Защита от дублирования
- ✅ Пользователь подтверждает

---

## 📋 Структура скрипта

```
install_safe_ssl.sh
├── Проверка прав root
├── Автоопределение Nextcloud
├── Интерактивные вопросы
│   ├── Путь к Nextcloud
│   ├── Выбор конфига Apache (с показом доменов)
│   ├── 1С сервер (с WebSocket URL)
│   └── Версия приложения
├── Установка
│   ├── Копирование файлов (из архива или директории)
│   ├── Настройка Apache
│   │   ├── Резервное копирование
│   │   ├── Включение модулей
│   │   ├── Поиск VirtualHost *:443 через awk
│   │   ├── Вставка директив перед </VirtualHost>
│   │   ├── Проверка синтаксиса
│   │   └── Применение или откат
│   ├── Установка приложения (occ)
│   └── Graceful reload Apache
├── Проверка
│   ├── Статус приложения
│   ├── Синтаксис Apache
│   └── Модули
└── Итог и рекомендации
```

---

## 🚀 Использование

```bash
# Запустите от root
sudo ./install_safe_ssl.sh

# Следуйте подсказкам:
# 1. Путь к Nextcloud
# 2. Выберите конфиг Apache (покажет домены)
# 3. Адрес 1С сервера
# 4. Версия приложения
```

---

## 🔍 Отличия от install_interactive.sh

| Функция | install_interactive.sh | install_safe_ssl.sh |
|---------|----------------------|---------------------|
| Поиск VirtualHost | sed (ненадёжно) | awk (надёжно) |
| Вставка директив | После SSLProxyEngine on | Перед </VirtualHost> |
| Резервное копирование | Базовое | Полное (конфиг, симлинк, приложение) |
| Проверка синтаксиса | После записи | До записи |
| Перезапуск Apache | restart | graceful |
| Выбор конфига | Простой список | С показом доменов |
| WebSocket URL | Не определён | Определён до использования |
| Проверка модулей | Нет | Есть |
| Защита от дублирования | Нет | Есть |

---

## ✅ Рекомендации

**Используйте `install_safe_ssl.sh` для:**
- ✅ Боевых серверов
- ✅ Сложных конфигураций Apache
- ✅ Нескольких VirtualHost
- ✅ Минимизации прерываний

**`install_interactive.sh` подойдёт для:**
- ✅ Тестовых серверов
- ✅ Простых конфигураций
- ✅ Быстрой установки

---

**Версия**: 3.1.1  
**Дата**: Март 2026  
**Nextcloud**: 31-32  
**Apache**: mod_proxy, mod_ssl, mod_headers, mod_rewrite, mod_proxy_wstunnel
