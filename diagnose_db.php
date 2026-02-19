<?php
// Скрипт диагностики базы данных Nextcloud
echo "=== Диагностика базы данных Nextcloud ===\n";

// Загружаем конфигурацию
$config_file = '/var/www/nextcloud/config/config.php';

if (!file_exists($config_file)) {
    die("Файл конфигурации не найден: $config_file\n");
}

// Создаем изолированное окружение для загрузки конфигурации
$CONFIG = [];
require_once $config_file;

if (!isset($CONFIG['dbtype']) || !isset($CONFIG['dbname']) || !isset($CONFIG['dbhost']) || 
    !isset($CONFIG['dbuser']) || !isset($CONFIG['dbpassword'])) {
    die("Конфигурация базы данных не найдена в файле конфигурации\n");
}

echo "Тип базы данных: " . $CONFIG['dbtype'] . "\n";
echo "Имя базы данных: " . $CONFIG['dbname'] . "\n";
echo "Хост базы данных: " . $CONFIG['dbhost'] . "\n";
echo "Пользователь базы данных: " . $CONFIG['dbuser'] . "\n";

try {
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];

    $dsn = '';
    switch ($CONFIG['dbtype']) {
        case 'mysql':
            $dsn = "mysql:host=" . $CONFIG['dbhost'] . ";dbname=" . $CONFIG['dbname'] . ";charset=utf8mb4";
            $options[PDO::MYSQL_ATTR_INIT_COMMAND] = "SET sql_mode='STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO'";
            break;
        case 'pgsql':
            $dsn = "pgsql:host=" . $CONFIG['dbhost'] . ";dbname=" . $CONFIG['dbname'];
            break;
        case 'sqlite':
            $dsn = "sqlite:" . $CONFIG['dbname'];
            break;
        default:
            throw new Exception("Неизвестный тип базы данных: " . $CONFIG['dbtype']);
    }

    $pdo = new PDO($dsn, $CONFIG['dbuser'], $CONFIG['dbpassword'], $options);
    echo "✓ Подключение к базе данных успешно установлено\n";

    // Проверяем, существуют ли основные таблицы Nextcloud
    $tables = ['oc_users', 'oc_filecache', 'oc_preferences', 'oc_share', 'oc_status'];
    echo "\nПроверка существования основных таблиц:\n";
    
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '" . $CONFIG['dbtableprefix'] . $table . "'");
        $result = $stmt->fetchAll();
        
        if (count($result) > 0) {
            echo "✓ Таблица " . $CONFIG['dbtableprefix'] . $table . " существует\n";
        } else {
            echo "? Таблица " . $CONFIG['dbtableprefix'] . $table . " не найдена\n";
        }
    }

    // Проверяем количество пользователей
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM " . $CONFIG['dbtableprefix'] . "users");
    $result = $stmt->fetch();
    echo "\nКоличество пользователей: " . $result['count'] . "\n";

    echo "\n✓ Диагностика базы данных завершена успешно\n";

} catch (Exception $e) {
    echo "✗ Ошибка при подключении к базе данных: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\n=== Диагностика завершена ===\n";