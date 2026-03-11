<?php

declare(strict_types=1);

return [
    'routes' => [
        // Главная страница приложения
        ['name' => 'page#index', 'url' => '/onec', 'verb' => 'GET'],
        
        // API для настроек
        ['name' => 'config#getDatabases', 'url' => '/api/databases', 'verb' => 'GET'],
        ['name' => 'config#saveDatabases', 'url' => '/api/databases', 'verb' => 'POST'],
        
        // Прокси к 1С (только для авторизованных!)
        ['name' => 'proxy#proxy', 'url' => '/1c-proxy/{basePath}/{path}', 'verb' => 'GET', 'requirements' => ['path' => '.+']],
        ['name' => 'proxy#proxyPost', 'url' => '/1c-proxy/{basePath}/{path}', 'verb' => 'POST', 'requirements' => ['path' => '.+']],
    ],
];
