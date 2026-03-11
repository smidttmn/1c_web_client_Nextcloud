<div id="app">
    <div id="app-navigation" class="without-app-settings">
        <button class="toggle-button" id="toggle-navigation" title="Свернуть меню" tabindex="-1">
            <span>←</span>
        </button>
        <ul id="navigation-list">
            <li class="navigation-header"><?php p($l->t('Базы 1С')); ?></li>
            <?php if (count($_['databases']) > 0): ?>
                <?php foreach ($_['databases'] as $database): ?>
                    <li class="navigation-item">
                        <a href="#" class="database-link"
                           data-url="<?php p($database['url']); ?>"
                           data-name="<?php p($database['name']); ?>">
                            <span class="icon-database"></span>
                            <?php p($database['name']); ?>
                        </a>
                    </li>
                <?php endforeach; ?>
            <?php else: ?>
                <li class="navigation-item no-databases">
                    <?php p($l->t('Нет настроенных баз')); ?>
                </li>
            <?php endif; ?>
        </ul>
    </div>
    
    <button class="expand-button" id="expand-navigation" title="Развернуть меню">
        <span>☰</span>
    </button>
    
    <div id="app-content">
        <div id="database-frame-wrapper">
            <div class="frame-header" id="frame-header" style="display:none;">
                <h3 id="frame-title"></h3>
                <button id="close-frame" class="icon-close" title="Закрыть">×</button>
            </div>
            <iframe id="database-frame"
                    sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation allow-downloads allow-pointer-lock allow-modals">
            </iframe>
            <div id="welcome-message" class="welcome-message">
                <h2><?php p($l->t('Добро пожаловать в 1C WebClient')); ?></h2>
                <p><?php p($l->t('Выберите базу 1С из меню слева для открытия')); ?></p>
            </div>
        </div>
    </div>
</div>

<style>
#app {
    display: flex;
    height: 100vh;
    overflow: hidden;
    position: relative;
}

/* Навигация - полупрозрачная парящая поверх всего */
#app-navigation {
    position: fixed;
    top: 0;
    left: -260px;
    width: 250px;
    height: 100vh;
    background-color: rgba(245, 245, 245, 0.7);
    backdrop-filter: blur(15px) saturate(180%);
    -webkit-backdrop-filter: blur(15px) saturate(180%);
    border-right: 1px solid rgba(255, 255, 255, 0.3);
    transition: left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 10000;
    display: flex;
    flex-direction: column;
    box-shadow: 5px 0 20px rgba(0, 0, 0, 0.15);
    pointer-events: none;
    opacity: 0;
}

#app-navigation.open {
    left: 0;
    pointer-events: auto;
    opacity: 1;
}

.toggle-button {
    position: absolute;
    top: 10px;
    right: 10px;
    width: 32px;
    height: 32px;
    background: rgba(0, 130, 201, 0.8);
    border: none;
    border-radius: 50%;
    cursor: pointer;
    font-size: 16px;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
    transition: all 0.3s;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.toggle-button:hover {
    background: rgba(0, 102, 163, 0.9);
    transform: scale(1.1);
}

#navigation-list {
    list-style: none;
    padding: 50px 10px 10px;
    margin: 0;
    overflow-y: auto;
    flex: 1;
}

.navigation-header {
    font-weight: bold;
    padding: 15px 10px;
    color: #555;
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
    margin-bottom: 5px;
    position: sticky;
    top: 0;
    background-color: transparent;
    z-index: 1;
    font-size: 14px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.navigation-item {
    margin-bottom: 3px;
    position: relative;
    z-index: 1;
}

.database-link {
    display: flex;
    align-items: center;
    padding: 12px 10px;
    color: #333;
    text-decoration: none;
    border-radius: 8px;
    transition: all 0.2s;
    cursor: pointer;
    position: relative;
    z-index: 1;
    background-color: transparent;
}

.database-link:hover {
    background-color: rgba(0, 130, 201, 0.15);
    transform: translateX(5px);
}

.icon-database {
    width: 20px;
    height: 20px;
    margin-right: 10px;
    background-color: #0082c9;
    -webkit-mask: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.02 2 6.5S6.48 11 12 11s10-2.02 10-4.5S17.52 2 12 2zm0 14c-5.52 0-10-2.02-10-4.5v3C2 16.98 6.48 19 12 19s10-2.02 10-4.5v-3c0 2.48-4.48 4.5-10 4.5zm0-5c-4.42 0-8-1.57-8-3.5S8.58 4 12 4s8 1.57 8 3.5-3.58 3.5-8 3.5zm0 9c-5.52 0-10-2.02-10-4.5v3C2 21.98 6.48 24 12 24s10-2.02 10-4.5v-3c0 2.48-4.48 4.5-10 4.5z"/></svg>') no-repeat center;
    mask: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 4.02 2 6.5S6.48 11 12 11s10-2.02 10-4.5S17.52 2 12 2zm0 14c-5.52 0-10-2.02-10-4.5v3C2 16.98 6.48 19 12 19s10-2.02 10-4.5v-3c0 2.48-4.48 4.5-10 4.5zm0-5c-4.42 0-8-1.57-8-3.5S8.58 4 12 4s8 1.57 8 3.5-3.58 3.5-8 3.5zm0 9c-5.52 0-10-2.02-10-4.5v3C2 21.98 6.48 24 12 24s10-2.02 10-4.5v-3c0 2.48-4.48 4.5-10 4.5z"/></svg>') no-repeat center;
}

.no-databases {
    color: #999;
    font-style: italic;
    padding: 10px;
}

/* Кнопка разворачивания - всегда видна в левом верхнем углу */
.expand-button {
    position: fixed;
    left: 10px;
    top: 60px;
    width: 44px;
    height: 44px;
    background: rgba(0, 130, 201, 0.8);
    border: none;
    border-radius: 50%;
    cursor: pointer;
    font-size: 22px;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9999;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
}

.expand-button:hover {
    background: rgba(0, 102, 163, 0.9);
    transform: scale(1.15) rotate(90deg);
}

/* Контент - фрейм на весь экран */
#app-content {
    flex: 1;
    display: flex;
    overflow: hidden;
    height: 100vh;
    width: 100%;
    position: relative;
    z-index: 1;
}

/* Фрейм на весь экран */
#database-frame-wrapper {
    display: flex;
    flex-direction: column;
    width: 100vw;
    height: 100vh;
    background-color: #fff;
    position: relative;
}

#database-frame {
    flex: 1;
    width: 100%;
    height: 100%;
    border: none;
    display: none;
    position: relative;
    z-index: 10;
}

#database-frame.active {
    display: block;
    width: 100%;
    height: 100%;
}

.frame-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 15px;
    background-color: #f0f0f0;
    border-bottom: 1px solid #ddd;
    flex-shrink: 0;
    position: relative;
    z-index: 20;
}

.frame-header h3 {
    margin: 0;
    font-size: 14px;
    font-weight: bold;
    color: #333;
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

#close-frame {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #666;
    padding: 0 10px;
    transition: color 0.3s;
}

#close-frame:hover {
    color: #e9322d;
}

/* Приветственное сообщение */
.welcome-message {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    width: 100%;
    text-align: center;
    color: #666;
    position: absolute;
    top: 0;
    left: 0;
    background-color: #fff;
    z-index: 5;
}

.welcome-message.hidden {
    display: none;
}

.welcome-message h2 {
    margin-bottom: 20px;
    color: #333;
}

.welcome-message p {
    font-size: 16px;
}

/* Адаптивность для мобильных */
@media (max-width: 768px) {
    #app-navigation {
        width: 200px;
    }
    
    .expand-button {
        top: 50px;
    }
    
    #database-frame-wrapper {
        width: 100%;
        height: 100%;
    }
    
    .welcome-message {
        width: 100%;
        height: 100%;
    }
}
</style>
