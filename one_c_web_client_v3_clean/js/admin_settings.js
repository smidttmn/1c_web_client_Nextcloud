// Ждем загрузки OC объектов и DOM
(function() {
    'use strict';

    // Получаем переводы
    const translations = {
        namePlaceholder: t('one_c_web_client', 'Название базы'),
        urlPlaceholder: t('one_c_web_client', 'URL базы (например, https://192.168.1.100/buh/)'),
        removeText: t('one_c_web_client', 'Удалить'),
        errorNoDatabases: t('one_c_web_client', 'Необходимо добавить хотя бы одну базу 1С'),
        savingSettings: t('one_c_web_client', 'Сохранение настроек'),
        successMessage: t('one_c_web_client', 'Настройки успешно сохранены'),
        defaultError: t('one_c_web_client', 'Ошибка сохранения настроек'),
        generalError: t('one_c_web_client', 'Ошибка сохранения настроек: ')
    };

    // Функция инициализации
    function init() {
        const form = document.getElementById('one_c_web_client_settings');
        const addDbBtn = document.getElementById('add-database');
        const dbsContainer = document.getElementById('databases-container');

        if (!form || !addDbBtn || !dbsContainer) {
            console.error('Required elements not found');
            return;
        }

        // Добавление новой базы
        addDbBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            const dbEntry = document.createElement('div');
            dbEntry.className = 'database-entry';

            const nameInput = document.createElement('input');
            nameInput.type = 'text';
            nameInput.className = 'db-name';
            nameInput.placeholder = translations.namePlaceholder;

            const urlInput = document.createElement('input');
            urlInput.type = 'text';
            urlInput.className = 'db-url';
            urlInput.placeholder = translations.urlPlaceholder;

            const removeButton = document.createElement('button');
            removeButton.type = 'button';
            removeButton.className = 'remove-db';
            removeButton.textContent = translations.removeText;

            dbEntry.appendChild(nameInput);
            dbEntry.appendChild(urlInput);
            dbEntry.appendChild(removeButton);

            dbsContainer.appendChild(dbEntry);
        });

        // Обработчики для кнопок удаления (делегирование событий)
        dbsContainer.addEventListener('click', function(e) {
            if (e.target.classList.contains('remove-db')) {
                const entry = e.target.parentElement;
                if (dbsContainer.children.length > 1) {
                    entry.remove();
                } else {
                    // Если это последняя запись, очищаем поля вместо удаления
                    entry.querySelector('.db-name').value = '';
                    entry.querySelector('.db-url').value = '';
                }
            }
        });

        // Сохранение настроек
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            e.stopPropagation();

            console.log('Form submitted');

            // Собираем данные о базах
            const dbEntries = document.querySelectorAll('.database-entry');
            const databases = [];

            dbEntries.forEach(entry => {
                const name = entry.querySelector('.db-name').value.trim();
                const url = entry.querySelector('.db-url').value.trim();

                if (name && url) {
                    databases.push({
                        name: name,
                        url: url
                    });
                }
            });

            console.log('Databases to save:', databases);

            // Проверяем, что есть хотя бы одна база
            if (databases.length === 0) {
                if (typeof OC !== 'undefined' && OC.msg) {
                    OC.msg.finishedAction('#one_c_web_client_settings_msg', {
                        status: 'error',
                        data: {message: translations.errorNoDatabases}
                    });
                } else {
                    alert(translations.errorNoDatabases);
                }
                return;
            }

            if (typeof OC !== 'undefined' && OC.msg) {
                OC.msg.startAction('#one_c_web_client_settings_msg', translations.savingSettings);
            }

            // Подготовка данных для отправки
            const settings = {
                databases: JSON.stringify(databases)
            };

            // Отправка данных на сервер
            const saveUrl = typeof OC !== 'undefined' && OC.generateUrl 
                ? OC.generateUrl('/apps/one_c_web_client/config/save')
                : '/apps/one_c_web_client/config/save';
            
            const requestToken = typeof OC !== 'undefined' && OC.requestToken 
                ? OC.requestToken 
                : document.querySelector('input[name="requesttoken"]')?.value || '';

            console.log('Saving to URL:', saveUrl);

            fetch(saveUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'requesttoken': requestToken
                },
                body: JSON.stringify(settings)
            })
            .then(response => {
                console.log('Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                if (data.status === 'success') {
                    if (typeof OC !== 'undefined' && OC.msg) {
                        OC.msg.finishedAction('#one_c_web_client_settings_msg', {
                            status: 'success',
                            data: {message: translations.successMessage}
                        });
                    } else {
                        alert(translations.successMessage);
                    }
                    // Перезагружаем страницу после успешного сохранения
                    setTimeout(function() {
                        window.location.reload();
                    }, 1000);
                } else {
                    if (typeof OC !== 'undefined' && OC.msg) {
                        OC.msg.finishedAction('#one_c_web_client_settings_msg', {
                            status: 'error',
                            data: {message: data.message || translations.defaultError}
                        });
                    } else {
                        alert(data.message || translations.defaultError);
                    }
                }
            })
            .catch(error => {
                console.error('Error saving settings:', error);
                const errorMessage = translations.generalError + error.message;
                if (typeof OC !== 'undefined' && OC.msg) {
                    OC.msg.finishedAction('#one_c_web_client_settings_msg', {
                        status: 'error',
                        data: {message: errorMessage}
                    });
                } else {
                    alert(errorMessage);
                }
            });
        });
    }

    // Ждем загрузки DOM и OC
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            // Небольшая задержка, чтобы OC успел загрузиться
            setTimeout(init, 100);
        });
    } else {
        // DOM уже загружен
        setTimeout(init, 100);
    }
})();
