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
            frame: !!frame
        });

        if (!frame || !frameContainer) {
            console.error('one_c_web_client_v3: Required elements not found');
            return;
        }

        // Функция открытия базы
        function openDatabase(url, dbName) {
            console.log('one_c_web_client_v3: Opening database:', { url, dbName });

            // Проверяем, что URL начинается с http или https
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                alert(translations.unsupportedProtocol);
                return;
            }

            // Открываем фрейм напрямую по HTTPS
            console.log('one_c_web_client_v3: Opening directly via HTTPS:', url);
            frame.src = url;
            frameTitle.textContent = dbName + ' - ' + url;

            // Показываем контейнер фрейма
            frameContainer.style.display = 'block';

            // Прокрутка к фрейму
            frameContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        // Обработчики для кнопок
        databaseButtons.forEach(button => {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                const url = this.getAttribute('data-url');
                const dbName = this.getAttribute('data-name');
                openDatabase(url, dbName);
            });
        });

        // Закрытие фрейма
        if (closeFrameBtn) {
            closeFrameBtn.addEventListener('click', function() {
                frame.src = 'about:blank';
                frameContainer.style.display = 'none';
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
