<div id="app">
    <div class="one-c-container">
        <h1><?php p($l->t('1C WebClient')); ?></h1>
        
        <?php if (count($_['databases']) > 0): ?>
            <div class="database-buttons">
                <?php foreach ($_['databases'] as $database): ?>
                    <div class="button-wrapper">
                        <button class="database-button" 
                                data-proxy-url="<?php p($_['proxyUrl']); ?>?url=<?php echo urlencode($database['url']); ?>"
                                data-url="<?php p($database['url']); ?>"
                                data-name="<?php p($database['name']); ?>">
                            <?php p($database['name']); ?>
                        </button>
                        <a href="<?php p($_['proxyUrl']); ?>?url=<?php echo urlencode($database['url']); ?>" 
                           target="_blank" 
                           class="open-new-window"
                           title="Открыть в новом окне"
                           rel="noopener noreferrer">
                            ↗
                        </a>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php else: ?>
            <div class="no-databases">
                <div class="no-databases-icon"></div>
                <p><?php p($l->t('Нет настроенных баз')); ?></p>
                <p class="small-text"><?php p($l->t('Обратитесь к администратору для настройки')); ?></p>
            </div>
        <?php endif; ?>
        
        <div class="info-message">
            <p>💡 <strong>Совет:</strong> Нажмите на кнопку для открытия базы через прокси Nextcloud, или на ↗ для открытия в новом окне</p>
        </div>
        
        <div id="database-frame-container" style="display:none;">
            <div class="frame-header">
                <h3 id="frame-title"></h3>
                <button class="close-button" id="close-frame" title="Закрыть">×</button>
            </div>
            <iframe id="database-frame"
                    sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation allow-downloads allow-pointer-lock allow-modals allow-popups-to-escape-sandbox">
            </iframe>
        </div>
    </div>
</div>

<style>
.one-c-container {
    padding: 40px 20px;
    max-width: 1400px;
    margin: 0 auto;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
}

h1 {
    color: white;
    margin-bottom: 40px;
    text-align: center;
    font-size: 2.5em;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
}

.database-buttons {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    justify-content: center;
    margin-bottom: 30px;
}

.button-wrapper {
    display: flex;
    align-items: center;
    gap: 10px;
}

.database-button {
    padding: 20px 40px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: 2px solid rgba(255,255,255,0.3);
    border-radius: 12px;
    cursor: pointer;
    font-size: 18px;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(0,0,0,0.2);
    min-width: 200px;
    flex: 0 1 auto;
}

.database-button:hover {
    transform: translateY(-3px);
    box-shadow: 0 6px 20px rgba(0,0,0,0.3);
    border-color: rgba(255,255,255,0.6);
}

.database-button:active {
    transform: translateY(-1px);
}

.open-new-window {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 45px;
    height: 45px;
    background: rgba(255,255,255,0.2);
    border: 2px solid rgba(255,255,255,0.3);
    border-radius: 12px;
    color: white;
    font-size: 24px;
    text-decoration: none;
    transition: all 0.3s ease;
}

.open-new-window:hover {
    background: rgba(255,255,255,0.3);
    border-color: rgba(255,255,255,0.6);
    transform: translateY(-3px);
}

.info-message {
    background: rgba(255,255,255,0.1);
    backdrop-filter: blur(10px);
    border-radius: 15px;
    padding: 20px 30px;
    text-align: center;
    color: white;
    border: 2px solid rgba(255,255,255,0.2);
    max-width: 600px;
    margin: 30px auto 0;
}

.info-message p {
    margin: 0;
    font-size: 16px;
}

.info-message strong {
    font-weight: 600;
}

.no-databases {
    background: rgba(255,255,255,0.1);
    backdrop-filter: blur(10px);
    border-radius: 20px;
    padding: 60px 40px;
    text-align: center;
    color: white;
    border: 2px solid rgba(255,255,255,0.2);
}

.no-databases-icon {
    width: 80px;
    height: 80px;
    margin: 0 auto 20px;
    background: rgba(255,255,255,0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 40px;
}

.no-databases p {
    font-size: 22px;
    margin: 10px 0;
}

.small-text {
    font-size: 16px;
    opacity: 0.8;
    margin-top: 15px;
}

#database-frame-container {
    margin-top: 30px;
    border-radius: 15px;
    overflow: hidden;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
    background: white;
}

.frame-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px 25px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
}

.frame-header h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 600;
}

.close-button {
    background: rgba(255,255,255,0.2);
    border: none;
    border-radius: 50%;
    width: 35px;
    height: 35px;
    font-size: 24px;
    cursor: pointer;
    color: white;
    transition: background 0.3s;
    display: flex;
    align-items: center;
    justify-content: center;
}

.close-button:hover {
    background: rgba(255,255,255,0.3);
}

#database-frame {
    width: 100%;
    height: calc(100vh - 300px);
    min-height: 600px;
    border: none;
}

/* Адаптивность для планшетов */
@media (max-width: 768px) {
    .one-c-container {
        padding: 20px 15px;
    }
    
    h1 {
        font-size: 2em;
    }
    
    .database-buttons {
        flex-direction: column;
        align-items: center;
    }
    
    .button-wrapper {
        width: 100%;
        max-width: 300px;
        justify-content: center;
    }
    
    .database-button {
        padding: 18px 30px;
        font-size: 16px;
    }
    
    .info-message {
        padding: 15px 20px;
    }
    
    .info-message p {
        font-size: 14px;
    }
    
    #database-frame {
        height: calc(100vh - 250px);
        min-height: 500px;
    }
}

/* Адаптивность для телефонов */
@media (max-width: 480px) {
    .one-c-container {
        padding: 15px 10px;
    }
    
    h1 {
        font-size: 1.5em;
        margin-bottom: 25px;
    }
    
    .database-button {
        padding: 15px 25px;
        font-size: 14px;
        min-width: 150px;
    }
    
    .open-new-window {
        width: 40px;
        height: 40px;
        font-size: 20px;
    }
    
    .frame-header {
        padding: 12px 15px;
    }
    
    .frame-header h3 {
        font-size: 14px;
    }
    
    .close-button {
        width: 30px;
        height: 30px;
        font-size: 20px;
    }
    
    #database-frame {
        height: calc(100vh - 220px);
        min-height: 400px;
    }
}
</style>
