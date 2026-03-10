<div id="app">
    <div id="controls">
        <div class="header">
            <div class="header-content">
                <div class="icon-1c">
                    <svg viewBox="0 0 100 100" fill="currentColor">
                        <rect x="5" y="5" width="90" height="90" rx="10" fill="rgba(255,255,255,0.2)"/>
                        <text x="50" y="70" font-family="Arial, sans-serif" font-size="50" font-weight="bold" fill="currentColor" text-anchor="middle">1С</text>
                    </svg>
                </div>
                <div class="header-text">
                    <h1><?php p($l->t('1С:Предприятие')); ?></h1>
                    <p><?php p($l->t('Выберите базу для подключения')); ?></p>
                </div>
            </div>
        </div>
        
        <div id="database-buttons" class="database-buttons">
            <!-- Кнопки будут добавлены через JS -->
        </div>
    </div>

    <div id="one_c_frame_container" class="frame-container hidden">
        <div class="frame-header">
            <span id="current-db-name" class="db-name"></span>
            <button id="close-frame" class="close-button" title="<?php p($l->t('Закрыть')); ?>">
                <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
            </button>
        </div>
        <iframe
            id="one_c_frame"
            name="one_c_frame"
            importance="high"
            allow="fullscreen"
            style="width: 100%; height: 100%; border: none;">
        </iframe>
    </div>
</div>

<style>
#app {
    width: 100%;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

#controls {
    padding: 0;
    background: transparent;
    border-bottom: none;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    flex-shrink: 0;
}

.header {
    padding: 30px 20px;
}

.header-content {
    max-width: 900px;
    margin: 0 auto;
    display: flex;
    align-items: center;
    gap: 20px;
}

.icon-1c {
    width: 80px;
    height: 80px;
    background: rgba(255,255,255,0.15);
    border-radius: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    flex-shrink: 0;
}

.icon-1c svg {
    width: 100%;
    height: 100%;
}

.header-text h1 {
    margin: 0;
    font-size: 28px;
    font-weight: 600;
    color: #fff;
}

.header-text p {
    margin: 5px 0 0 0;
    font-size: 14px;
    color: rgba(255,255,255,0.8);
}

.database-buttons {
    padding: 0 20px 25px;
    max-width: 900px;
    margin: 0 auto;
    display: flex;
    gap: 15px;
    flex-wrap: wrap;
    align-content: flex-start;
    max-height: 400px;
    overflow-y: auto;
    scrollbar-width: thin;
    scrollbar-color: rgba(255,255,255,0.5) rgba(255,255,255,0.1);
    border-radius: 12px;
    padding-right: 10px;
}

/* Кастомный скроллбар для Chrome/Safari/Edge */
.database-buttons::-webkit-scrollbar {
    width: 8px;
}

.database-buttons::-webkit-scrollbar-track {
    background: rgba(255,255,255,0.1);
    border-radius: 4px;
}

.database-buttons::-webkit-scrollbar-thumb {
    background: rgba(255,255,255,0.5);
    border-radius: 4px;
    transition: background 0.2s;
}

.database-buttons::-webkit-scrollbar-thumb:hover {
    background: rgba(255,255,255,0.7);
}

.database-button {
    padding: 16px 32px;
    background: rgba(255,255,255,0.95);
    color: #667eea;
    border: none;
    border-radius: 12px;
    cursor: pointer;
    font-size: 16px;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    display: flex;
    align-items: center;
    gap: 10px;
    flex-shrink: 0;
}

.database-button:hover {
    background: #fff;
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.database-button:active {
    transform: translateY(0);
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.database-button svg {
    width: 24px;
    height: 24px;
}

/* Иконки для разных баз */
.database-button[data-db-id="accounting"] svg {
    color: #2ecc71;
}

.database-button[data-db-id="hr"] svg {
    color: #e74c3c;
}

/* Адаптив для телефонов */
@media (max-width: 768px) {
    .header-content {
        flex-direction: column;
        text-align: center;
    }

    .header-text h1 {
        font-size: 22px;
    }

    .database-buttons {
        max-height: 50vh;
        gap: 10px;
        padding: 0 15px 20px;
    }

    .database-button {
        padding: 14px 20px;
        font-size: 15px;
        width: calc(50% - 10px);
        justify-content: center;
    }

    .database-button svg {
        width: 20px;
        height: 20px;
    }
}

/* Для очень маленьких экранов */
@media (max-width: 480px) {
    .database-button {
        width: 100%;
        justify-content: flex-start;
    }

    .header {
        padding: 20px 15px;
    }

    .header-text h1 {
        font-size: 20px;
    }
}

.frame-container {
    flex: 1;
    position: relative;
    width: 100%;
    height: calc(100vh - 180px);
    background: #fff;
    box-shadow: inset 0 0 20px rgba(0,0,0,0.05);
}

.frame-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 20px;
    background: #f8f9fa;
    border-bottom: 1px solid #e9ecef;
}

.db-name {
    font-size: 16px;
    font-weight: 600;
    color: #495057;
}

.close-button {
    padding: 8px;
    background: transparent;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    color: #6c757d;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
}

.close-button:hover {
    background: #e9ecef;
    color: #dc3545;
}

.close-button svg {
    width: 20px;
    height: 20px;
}

#one_c_frame {
    width: 100%;
    height: calc(100% - 53px);
    border: none;
    display: block;
}

.hidden {
    display: none !important;
}
</style>
