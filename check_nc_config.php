<?php
// Скрипт диагностики ошибок Nextcloud
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

echo "=== Диагностика ошибок Nextcloud ===\n";

// Проверяем, существуют ли необходимые файлы
$required_files = [
    '/var/www/nextcloud/3rdparty/autoload.php',
    '/var/www/nextcloud/lib/base.php',
    '/var/www/nextcloud/config/config.php'
];

foreach ($required_files as $file) {
    if (file_exists($file)) {
        echo "✓ Файл существует: $file\n";
    } else {
        echo "✗ Файл не существует: $file\n";
    }
}

// Проверяем права доступа к основным директориям
$dirs = [
    '/var/www/nextcloud',
    '/var/www/nextcloud/config',
    '/var/www/nextcloud/data',
    '/var/www/nextcloud/apps'
];

foreach ($dirs as $dir) {
    if (is_readable($dir)) {
        echo "✓ Директория читаема: $dir\n";
        if (is_writable($dir)) {
            echo "✓ Директория записываема: $dir\n";
        } else {
            echo "✗ Директория не записываема: $dir\n";
        }
    } else {
        echo "✗ Директория не читаема: $dir\n";
    }
}

// Проверяем подключение к базе данных (если конфигурация доступна)
$config_file = '/var/www/nextcloud/config/config.php';
if (file_exists($config_file)) {
    // Создаем изолированное окружение для загрузки конфигурации
    $CONFIG = [];
    require_once $config_file;
    
    if (isset($CONFIG['dbtype'])) {
        echo "✓ Тип базы данных: " . $CONFIG['dbtype'] . "\n";
    } else {
        echo "✗ Тип базы данных не указан в конфигурации\n";
    }
    
    if (isset($CONFIG['dbname'])) {
        echo "✓ Имя базы данных: " . $CONFIG['dbname'] . "\n";
    }
    
    if (isset($CONFIG['dbhost'])) {
        echo "✓ Хост базы данных: " . $CONFIG['dbhost'] . "\n";
    }
    
    if (isset($CONFIG['dbuser'])) {
        echo "✓ Пользователь базы данных: " . $CONFIG['dbuser'] . "\n";
    }
}

// Проверяем установленные расширения PHP
$required_extensions = ['gd', 'curl', 'dom', 'fileinfo', 'iconv', 'intl', 'json', 'mbstring', 'openssl', 'pdo', 'zip', 'xml', 'zlib'];
$loaded_extensions = get_loaded_extensions();
$missing_extensions = [];

foreach ($required_extensions as $ext) {
    if (!in_array($ext, $loaded_extensions)) {
        $missing_extensions[] = $ext;
    }
}

if (empty($missing_extensions)) {
    echo "✓ Все необходимые расширения PHP установлены\n";
} else {
    echo "✗ Отсутствуют следующие расширения PHP: " . implode(', ', $missing_extensions) . "\n";
}

echo "=== Диагностика завершена ===\n";