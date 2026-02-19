<div class="section">
    <h2><?php p($l->t('Настройки 1C WebClient')); ?></h2>

    <p><?php p($l->t('Здесь вы можете настроить список баз 1С, к которым пользователи смогут получить доступ.')); ?></p>

    <!-- Скрытый элемент для передачи переводимых строк в JavaScript -->
    <div id="one_c_web_client_data"
         data-name-placeholder="<?php p(addslashes($l->t('Название базы'))); ?>"
         data-url-placeholder="<?php p(addslashes($l->t('URL базы (например, http://10.72.1.5/sgtbuh/)'))); ?>"
         data-remove-text="<?php p(addslashes($l->t('Удалить'))); ?>"
         data-error-no-databases="<?php p(addslashes($l->t('Необходимо добавить хотя бы одну базу 1С'))); ?>"
         data-saving-settings="<?php p(addslashes($l->t('Сохранение настроек'))); ?>"
         data-success-message="<?php p(addslashes($l->t('Настройки успешно сохранены'))); ?>"
         data-default-error="<?php p(addslashes($l->t('Ошибка сохранения настроек'))); ?>"
         data-general-error="<?php p(addslashes($l->t('Ошибка сохранения настроек: '))); ?>"
         style="display: none;"></div>

    <form id="one_c_web_client_settings">
        <h3><?php p($l->t('Базы данных 1С')); ?></h3>
        
        <div id="databases-container">
            <?php if (empty($_['databases'])): ?>
                <div class="database-entry">
                    <input type="text" class="db-name" placeholder="<?php p($l->t('Название базы')); ?>" />
                    <input type="text" class="db-url" placeholder="<?php p($l->t('URL базы (например, http://10.72.1.5/sgtbuh/)')); ?>" />
                    <button type="button" class="remove-db" style="display:none;"><?php p($l->t('Удалить')); ?></button>
                </div>
            <?php else: ?>
                <?php foreach ($_['databases'] as $db): ?>
                    <div class="database-entry">
                        <input type="text" class="db-name" value="<?php p($db['name']); ?>" placeholder="<?php p($l->t('Название базы')); ?>" />
                        <input type="text" class="db-url" value="<?php p($db['url']); ?>" placeholder="<?php p($l->t('URL базы (например, http://10.72.1.5/sgtbuh/)')); ?>" />
                        <button type="button" class="remove-db"><?php p($l->t('Удалить')); ?></button>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>

        <button type="button" id="add-database"><?php p($l->t('Добавить базу')); ?></button>
        <button type="submit"><?php p($l->t('Сохранить настройки')); ?></button>
    </form>

    <div id="one_c_web_client_settings_msg" class="msg"></div>
</div>

<style>
.database-entry {
    display: flex;
    gap: 10px;
    margin-bottom: 10px;
    align-items: center;
    flex-wrap: wrap;
}

.database-entry input {
    flex: 1;
    min-width: 200px;
    padding: 5px;
}

.remove-db {
    background-color: #e9322d;
    color: white;
    border: none;
    padding: 5px 10px;
    cursor: pointer;
    border-radius: 3px;
}

#add-database {
    background-color: #0082c9;
    color: white;
    border: none;
    padding: 8px 15px;
    cursor: pointer;
    border-radius: 3px;
    margin-right: 10px;
}

#one_c_web_client_settings_msg {
    margin-top: 15px;
}

.section {
    padding: 20px 0;
    border-bottom: 1px solid #eee;
}
</style>