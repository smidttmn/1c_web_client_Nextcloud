<?php
// Скрипт для диагностики состояния Nextcloud
require_once '/var/www/nextcloud/htdocs/3rdparty/autoload.php';

try {
    // Проверяем, можно ли подключиться к базе данных
    $config = \OC::$server->getConfig();
    $dbType = $config->getSystemValue('dbtype', 'sqlite');
    echo "Тип базы данных: " . $dbType . "\n";
    
    // Проверяем, есть ли доступ к объекту базы данных
    $connection = \OC::$server->getDatabaseConnection();
    if ($connection) {
        echo "Подключение к базе данных: OK\n";
    } else {
        echo "Подключение к базе данных: FAILED\n";
    }
    
    // Проверяем версию Nextcloud
    $version = \OC_Util::getVersionString();
    echo "Версия Nextcloud: " . $version . "\n";
    
} catch (Exception $e) {
    echo "Ошибка при попытке диагностики: " . $e->getMessage() . "\n";
    error_log("Nextcloud diagnosis error: " . $e->getMessage());
}