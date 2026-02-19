<?php
// Скрипт диагностики Nextcloud
echo "=== Диагностика Nextcloud ===\n";

// Проверка расширений PHP
echo "Проверка PHP-расширений:\n";
$required_extensions = ['gd', 'curl', 'dom', 'fileinfo', 'iconv', 'intl', 'json', 'mbstring', 'openssl', 'pdo', 'sqlite3', 'xml', 'zip', 'zlib', 'mysql'];

foreach ($required_extensions as $ext) {
    if (extension_loaded($ext)) {
        echo "✓ $ext\n";
    } else {
        echo "✗ $ext - отсутствует!\n";
    }
}

echo "\nПроверка доступа к файлам Nextcloud:\n";

$paths = [
    '/var/www/nextcloud/3rdparty/autoload.php',
    '/var/www/nextcloud/lib/base.php',
    '/var/www/nextcloud/config/config.php',
    '/var/www/nextcloud/apps',
    '/var/www/nextcloud/data',
    '/var/www/nextcloud/themes'
];

foreach ($paths as $path) {
    if (file_exists($path)) {
        if (is_readable($path)) {
            echo "✓ $path - доступен\n";
        } else {
            echo "✗ $path - недоступен для чтения\n";
        }
    } else {
        echo "? $path - не существует\n";
    }
}

// Проверка конфигурации базы данных
echo "\nПроверка конфигурации базы данных:\n";
if (file_exists('/var/www/nextcloud/config/config.php')) {
    include '/var/www/nextcloud/config/config.php';
    
    if (isset($CONFIG['dbtype'])) {
        echo "Тип базы данных: " . $CONFIG['dbtype'] . "\n";
    }
    
    if (isset($CONFIG['dbname'])) {
        echo "Имя базы данных: " . $CONFIG['dbname'] . "\n";
    }
    
    if (isset($CONFIG['dbhost'])) {
        echo "Хост базы данных: " . $CONFIG['dbhost'] . "\n";
    }
    
    // Попытка подключения к базе данных
    if (isset($CONFIG['dbtype']) && isset($CONFIG['dbname']) && isset($CONFIG['dbhost']) && 
        isset($CONFIG['dbuser']) && isset($CONFIG['dbpassword'])) {
        
        echo "Попытка подключения к базе данных...\n";
        try {
            $dsn = $CONFIG['dbtype'] . ':host=' . $CONFIG['dbhost'] . ';dbname=' . $CONFIG['dbname'];
            $pdo = new PDO($dsn, $CONFIG['dbuser'], $CONFIG['dbpassword']);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            echo "✓ Подключение к базе данных успешно\n";
        } catch (PDOException $e) {
            echo "✗ Ошибка подключения к базе данных: " . $e->getMessage() . "\n";
        }
    }
} else {
    echo "Не удалось загрузить конфигурацию\n";
}

echo "\n=== Диагностика завершена ===\n";