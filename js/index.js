// Ждем загрузки DOM и OC
(function() {
    'use strict';

    // Переводы
    const translations = {
        unsupportedProtocol: t('one_c_web_client', 'Неподдерживаемый протокол. URL должен начинаться с http:// или https://'),
        frameLoaded: t('one_c_web_client', 'Фрейм успешно загружен'),
        frameError: t('one_c_web_client', 'Ошибка загрузки страницы. Пожалуйста, проверьте доступность ресурса.')
    };

    // Функция инициализации
    function init() {
        console.log('one_c_web_client: Initializing...');
        
        const databaseLinks = document.querySelectorAll('.database-link');
        const frame = document.getElementById('database-frame');
        const frameWrapper = document.getElementById('database-frame-wrapper');
        const frameTitle = document.getElementById('frame-title');
        const frameHeader = document.getElementById('frame-header');
        const closeFrameBtn = document.getElementById('close-frame');
        const toggleNavBtn = document.getElementById('toggle-navigation');
        const appNavigation = document.getElementById('app-navigation');
        const welcomeMessage = document.getElementById('welcome-message');

        console.log('one_c_web_client: Elements found:', {
            databaseLinks: databaseLinks.length,
            frame: !!frame,
            frameWrapper: !!frameWrapper,
            frameTitle: !!frameTitle
        });

        if (!frame || !frameWrapper || !frameTitle) {
            console.error('one_c_web_client: Required elements not found');
            return;
        }

        // Функция открытия базы
        function openDatabase(url, dbName) {
            console.log('one_c_web_client: Opening database:', { url, dbName });

            // Проверяем, что URL начинается с http или https
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                alert(translations.unsupportedProtocol);
                return;
            }

            // Открываем фрейм напрямую по HTTPS
            console.log('one_c_web_client: Opening directly via HTTPS:', url);
            frame.src = url;
            frameTitle.textContent = dbName + ' - ' + url;

            // Показываем фрейм и заголовок
            frame.classList.add('active');
            if (frameHeader) {
                frameHeader.style.display = 'flex';
            }

            // Скрываем приветственное сообщение
            if (welcomeMessage) {
                welcomeMessage.classList.add('hidden');
            }

            console.log('one_c_web_client: Frame opened');
        }

        // Обработчики для ссылок в навигации
        databaseLinks.forEach(link => {
            link.addEventListener('click', function(e) {
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
                frame.classList.remove('active');
                if (frameHeader) {
                    frameHeader.style.display = 'none';
                }
                if (welcomeMessage) {
                    welcomeMessage.classList.remove('hidden');
                }
            });
        }

        // Сворачивание/разворачивание меню
        if (toggleNavBtn && appNavigation) {
            toggleNavBtn.addEventListener('click', function() {
                appNavigation.classList.toggle('open');
                localStorage.setItem('one_c_web_client_nav_open', appNavigation.classList.contains('open'));
                
                // Убираем tabindex когда меню закрыто
                if (appNavigation.classList.contains('open')) {
                    toggleNavBtn.setAttribute('tabindex', '0');
                } else {
                    toggleNavBtn.setAttribute('tabindex', '-1');
                }
            });

            // По умолчанию меню закрыто
            appNavigation.classList.remove('open');
            localStorage.setItem('one_c_web_client_nav_open', 'false');
            toggleNavBtn.setAttribute('tabindex', '-1');
        }

        // Разворачивание меню через внешнюю кнопку
        const expandNavBtn = document.getElementById('expand-navigation');
        if (expandNavBtn && appNavigation) {
            expandNavBtn.addEventListener('click', function() {
                appNavigation.classList.add('open');
                localStorage.setItem('one_c_web_client_nav_open', 'true');
            });
        }

        // Обработчики для iframe
        frame.addEventListener('load', function() {
            console.log('one_c_web_client: Фрейм успешно загружен');
            console.log('one_c_web_client: Frame src:', frame.src);
        });

        frame.addEventListener('error', function() {
            console.error('one_c_web_client: Ошибка загрузки фрейма');
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
