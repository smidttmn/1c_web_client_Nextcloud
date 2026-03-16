<div id="app">
    <div class="one-c-container">
        <h1><?php p($l->t('1C WebClient')); ?></h1>
        
        <?php if (count($_['databases']) > 0): ?>
            <div class="database-buttons">
                <?php foreach ($_['databases'] as $database): ?>
                    <button class="database-button" 
                            data-url="<?php p($database['url']); ?>"
                            data-name="<?php p($database['name']); ?>">
                        <?php p($database['name']); ?>
                    </button>
                <?php endforeach; ?>
            </div>
        <?php else: ?>
            <p class="no-databases"><?php p($l->t('Нет настроенных баз')); ?></p>
        <?php endif; ?>
        
        <div id="database-frame-container" style="display:none;">
            <div class="frame-header">
                <h3 id="frame-title"></h3>
                <button class="close-button" id="close-frame">×</button>
            </div>
            <iframe id="database-frame"
                    sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation allow-downloads allow-pointer-lock allow-modals">
            </iframe>
        </div>
    </div>
</div>

<style>
.one-c-container {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
}

h1 {
    color: #333;
    margin-bottom: 30px;
}

.database-buttons {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    margin-bottom: 30px;
}

.database-button {
    padding: 15px 30px;
    background-color: #0082c9;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-size: 16px;
    transition: background-color 0.3s;
}

.database-button:hover {
    background-color: #00679e;
}

.no-databases {
    color: #666;
    font-size: 18px;
    padding: 40px;
    text-align: center;
    background-color: #f5f5f5;
    border-radius: 8px;
}

#database-frame-container {
    margin-top: 20px;
    border: 1px solid #ddd;
    border-radius: 8px;
    overflow: hidden;
}

.frame-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 15px;
    background-color: #f0f0f0;
    border-bottom: 1px solid #ddd;
}

.frame-header h3 {
    margin: 0;
    font-size: 14px;
    color: #333;
}

.close-button {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #666;
    padding: 0 10px;
}

.close-button:hover {
    color: #e9322d;
}

#database-frame {
    width: 100%;
    height: 600px;
    border: none;
}
</style>
