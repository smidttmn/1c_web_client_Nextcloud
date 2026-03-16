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

        console.log('one_c_web_client_v3: Buttons found:', databaseButtons.length);

        // Обработчики для кнопок - открываем в НОВОМ ОКНЕ
        databaseButtons.forEach(button => {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                const url = this.getAttribute('data-url');
                const dbName = this.getAttribute('data-name');
                
                console.log('one_c_web_client_v3: Opening database in new window:', { url, dbName });

                // Проверяем, что URL начинается с http или https
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    alert(translations.unsupportedProtocol);
                    return;
                }

                // Открываем в НОВОМ ОКНЕ
                const newWindow = window.open(url, '_blank', 'noopener,noreferrer');
                
                if (!newWindow) {
                    alert('Браузер заблокировал открытие нового окна. Пожалуйста, разрешите всплывающие окна для этого сайта.');
                }
            });
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
