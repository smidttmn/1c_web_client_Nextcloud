// Ждем загрузки DOM и OC
(function() {
    'use strict';

    // Переводы
    const translations = {
        unsupportedProtocol: t('one_c_web_client_v3', 'Неподдерживаемый протокол. URL должен начинаться с http:// или https://')
    };

    // Функция инициализации
    function init() {
        console.log('one_c_web_client_v3: Initializing...');

        const databaseButtons = document.querySelectorAll('.database-button');
        const frameContainer = document.getElementById('database-frame-container');
        const frame = document.getElementById('database-frame');
        const frameTitle = document.getElementById('frame-title');
        const closeFrameBtn = document.getElementById('close-frame');

        console.log('one_c_web_client_v3: Elements found:', {
            databaseButtons: databaseButtons.length,
            frameContainer: !!frameContainer,
            frame: !!frame,
            frameTitle: !!frameTitle,
            closeFrameBtn: !!closeFrameBtn
        });

        if (!frame || !frameContainer) {
            console.error('one_c_web_client_v3: Required elements not found');
            return;
        }

        // Обработчики для кнопок
        databaseButtons.forEach(button => {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                const url = this.getAttribute('data-url');
                const dbName = this.getAttribute('data-name');
                
                console.log('one_c_web_client_v3: Opening database:', { url, dbName });

                // Проверяем, что URL начинается с http или https
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    alert(translations.unsupportedProtocol);
                    return;
                }

                // Извлекаем путь из URL (например, /sgtbuh из https://10.72.1.5/sgtbuh)
                const urlPath = new URL(url).pathname;
                
                // Открываем через прокси Nextcloud: /one_c_web_client_v3 + путь
                const proxyPath = '/one_c_web_client_v3' + urlPath;
                
                console.log('one_c_web_client_v3: Opening via proxy:', proxyPath);
                
                openDatabase(proxyPath, dbName);
            });
        });

        // Закрытие фрейма
        if (closeFrameBtn) {
            closeFrameBtn.addEventListener('click', function(e) {
                e.preventDefault();
                console.log('one_c_web_client_v3: Closing frame');
                
                frameContainer.style.display = 'none';
                setTimeout(() => {
                    frame.src = 'about:blank';
                }, 100);
            });
        } else {
            console.error('one_c_web_client_v3: Close button not found');
        }
    }

    // Функция открытия базы
    function openDatabase(path, dbName) {
        const frameContainer = document.getElementById('database-frame-container');
        const frame = document.getElementById('database-frame');
        const frameTitle = document.getElementById('frame-title');

        if (!frame || !frameContainer) {
            console.error('one_c_web_client_v3: Required elements not found');
            return;
        }

        console.log('one_c_web_client_v3: Opening database:', path);
        
        frameContainer.style.display = 'none';
        frame.src = path;
        frameTitle.textContent = dbName;
        
        setTimeout(() => {
            frameContainer.style.display = 'block';
            frameContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }, 100);
    }

    // Ждем загрузки DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(init, 100);
        });
    } else {
        setTimeout(init, 100);
    }
})();
