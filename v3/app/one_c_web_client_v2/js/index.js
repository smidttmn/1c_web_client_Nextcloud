// Ждем загрузки DOM и OC
(function() {
    'use strict';

    // Массив баз данных 1С (загружается из настроек)
    let databases = [];

    function init() {
        console.log('one_c_web_client: Initializing...');

        const databaseButtons = document.getElementById('database-buttons');

        if (!databaseButtons) {
            console.error('one_c_web_client: Required elements not found');
            return;
        }

        // Загружаем базы из настроек
        loadDatabases().then(() => {
            // Рендерим меню с кнопками баз данных
            renderMenu(databaseButtons);
        });
    }

    /**
     * Загружает список баз из настроек приложения
     */
    function loadDatabases() {
        return fetch(OC.generateUrl('/apps/one_c_web_client_v2/api/databases'))
            .then(response => response.json())
            .then(data => {
                if (data && Array.isArray(data) && data.length > 0) {
                    databases = data;
                    console.log('one_c_web_client: Databases loaded:', databases);
                } else {
                    databases = [];
                    console.log('one_c_web_client: No databases configured');
                }
            })
            .catch(err => {
                console.error('one_c_web_client: Error loading databases:', err);
                databases = [];
            });
    }

    /**
     * Открывает базу 1С в новом окне
     * @param {string} dbId - идентификатор базы
     */
    function openDatabase(dbId) {
        console.log('one_c_web_client: Opening database:', dbId);

        const db = databases.find(d => d.id === dbId);
        if (!db) {
            console.error('one_c_web_client: Database not found:', dbId);
            return;
        }

        // Прямой прокси: /accounting/ → https://192.168.1.10/accounting/
        const proxyUrl = window.location.protocol + '//' + window.location.host + '/' + dbId + '/';

        console.log('one_c_web_client: Opening in new window:', proxyUrl);

        const newWindow = window.open(proxyUrl, '_blank', 'width=1400,height=900');
        
        if (!newWindow) {
            console.error('one_c_web_client: Popup blocked!');
            alert('Браузер заблокировал открытие окна. Разрешите popup для этого сайта.');
        }
    }

    /**
     * Рендерит кнопки баз данных с иконками
     */
    function renderMenu(container) {
        console.log('one_c_web_client: Rendering menu, databases:', databases);

        container.innerHTML = '';

        if (databases.length === 0) {
            container.innerHTML = '<p style="color: #fff; font-size: 16px;">Базы данных не настроены. Обратитесь к администратору.</p>';
            return;
        }

        databases.forEach(db => {
            const button = document.createElement('button');
            button.className = 'database-button';
            button.setAttribute('data-db-id', db.id);

            // Иконка для базы
            const iconSvg = db.id === 'accounting' 
                ? '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M4 10v7h3v-7H4zm6 0v7h3v-7h-3zM2 22h19v-3H2v3zm14-17v3h3v-3h-3zm-3 5h3v-3h-3v3zm-3-5v3H7V5h3zM7 10v7H4v-7h3zm12 0v7h-3v-7h3z"/></svg>'
                : '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>';

            button.innerHTML = iconSvg + '<span>' + db.name + '</span>';

            button.addEventListener('click', function(e) {
                e.preventDefault();
                openDatabase(db.id);
            });

            container.appendChild(button);
            console.log('one_c_web_client: Added button for', db.name);
        });
    }

    console.log('one_c_web_client: Initialization complete');

    // Запуск после загрузки DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => setTimeout(init, 100));
    } else {
        setTimeout(init, 100);
    }
})();
