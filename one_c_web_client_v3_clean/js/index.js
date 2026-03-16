// Ждем загрузки DOM и OC
(function() {
    'use strict';

    // Переводы
    const translations = {
        unsupportedProtocol: t('one_c_web_client_v3', 'Неподдерживаемый протокол. URL должен начинаться с http:// или https://'),
        frameLoaded: t('one_c_web_client_v3', 'Фрейм успешно загружен'),
        frameError: t('one_c_web_client_v3', 'Ошибка загрузки страницы. Пожалуйста, проверьте доступность ресурса.')
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

        // Функция открытия базы через ПРОКСИ
        function openDatabase(proxyUrl, url, dbName) {
            console.log('one_c_web_client_v3: Opening database via PROXY:', { proxyUrl, url, dbName });

            // Проверяем, что URL начинается с http или https
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                alert(translations.unsupportedProtocol);
                return;
            }

            // Открываем через прокси Nextcloud
            console.log('one_c_web_client_v3: Using proxy:', proxyUrl);
            
            // Сначала скрываем, потом меняем src, потом показываем
            frameContainer.style.display = 'none';
            frame.src = proxyUrl;
            frameTitle.textContent = dbName;
            
            // Показываем контейнер фрейма
            frameContainer.style.display = 'block';

            // Прокрутка к фрейму
            setTimeout(() => {
                frameContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }, 100);
        }

        // Обработчики для кнопок - открываем через ПРОКСИ
        databaseButtons.forEach(button => {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                const proxyUrl = this.getAttribute('data-proxy-url');
                const url = this.getAttribute('data-url');
                const dbName = this.getAttribute('data-name');
                openDatabase(proxyUrl, url, dbName);
            });
        });

        // Закрытие фрейма
        if (closeFrameBtn) {
            closeFrameBtn.addEventListener('click', function() {
                // Очищаем src и скрываем контейнер
                frameContainer.style.display = 'none';
                setTimeout(() => {
                    frame.src = 'about:blank';
                }, 100);
            });
        }

        // Обработчики для iframe
        frame.addEventListener('load', function() {
            console.log('one_c_web_client_v3: Фрейм успешно загружен');
            console.log('one_c_web_client_v3: Frame src:', frame.src);
        });

        frame.addEventListener('error', function() {
            console.error('one_c_web_client_v3: Ошибка загрузки фрейма');
            alert(translations.frameError);
        });
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
