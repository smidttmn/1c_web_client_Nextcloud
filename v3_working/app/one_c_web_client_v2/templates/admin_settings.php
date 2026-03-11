<div id="onec-admin-settings" class="section">
	<h2><?php p($l->t('Базы данных 1С')); ?></h2>
	<p class="settings-hint"><?php p($l->t('Настройте список баз 1С, которые будут доступны пользователям')); ?></p>

	<div id="databases-list">
		<!-- Список баз будет загружен через JS -->
	</div>

	<button id="add-database" class="primary"><?php p($l->t('+ Добавить базу')); ?></button>

	<div id="database-form" style="display: none; margin-top: 20px;">
		<h3><?php p($l->t('Добавление базы 1С')); ?></h3>
		
		<p>
			<label for="db-name"><?php p($l->t('Название:')); ?></label>
			<input type="text" id="db-name" placeholder="<?php p($l->t('Например, Бухгалтерия')); ?>" style="width: 100%;">
		</p>

		<p>
			<label for="db-id"><?php p($l->t('Идентификатор (латиницей):')); ?></label>
			<input type="text" id="db-id" placeholder="<?php p($l->t('Например, accounting')); ?>" style="width: 100%;">
		</p>

		<p>
			<label for="db-url"><?php p($l->t('URL доступа (HTTPS):')); ?></label>
			<input type="url" id="db-url" placeholder="<?php p($l->t('Например, https://192.168.1.10/accounting')); ?>" style="width: 100%;">
		</p>

		<p>
			<button id="save-database" class="primary"><?php p($l->t('Сохранить')); ?></button>
			<button id="cancel-database"><?php p($l->t('Отмена')); ?></button>
		</p>
	</div>

	<div id="save-status" style="margin-top: 10px;"></div>
</div>

<script>
(function() {
	'use strict';

	let databases = [];
	let editingIndex = -1;
	
	// Получаем URL через data-атрибут (если OC недоступен)
	const apiUrl = typeof OC !== 'undefined' 
		? OC.generateUrl('/apps/one_c_web_client_v2/api/databases')
		: '/index.php/apps/one_c_web_client_v2/api/databases';

	// Загрузка баз при старте
	loadDatabases();

	// Кнопка добавления
	document.getElementById('add-database').addEventListener('click', function() {
		document.getElementById('database-form').style.display = 'block';
		editingIndex = -1;
		clearForm();
	});

	// Кнопка отмены
	document.getElementById('cancel-database').addEventListener('click', function() {
		document.getElementById('database-form').style.display = 'none';
		clearForm();
	});

	// Кнопка сохранения
	document.getElementById('save-database').addEventListener('click', saveDatabase);

	function loadDatabases() {
		fetch(apiUrl)
			.then(response => response.json())
			.then(data => {
				databases = data || [];
				renderDatabases();
			})
			.catch(err => {
				console.error('Error loading databases:', err);
				showStatus('Ошибка загрузки баз', 'error');
			});
	}

	function renderDatabases() {
		const container = document.getElementById('databases-list');
		container.innerHTML = '';

		if (databases.length === 0) {
			container.innerHTML = '<p><em>Базы данных не настроены. Добавьте первую базу!</em></p>';
			return;
		}

		const table = document.createElement('table');
		table.className = 'grid';
		table.style.width = '100%';
		table.style.marginTop = '20px';

		const header = `
			<thead>
				<tr>
					<th><?php p($l->t('Название')); ?></th>
					<th><?php p($l->t('ID')); ?></th>
					<th><?php p($l->t('URL')); ?></th>
					<th><?php p($l->t('Действия')); ?></th>
				</tr>
			</thead>
		`;
		table.innerHTML = header;

		const tbody = document.createElement('tbody');
		databases.forEach((db, index) => {
			const row = document.createElement('tr');
			row.innerHTML = `
				<td>${escapeHtml(db.name)}</td>
				<td>${escapeHtml(db.id)}</td>
				<td>${escapeHtml(db.url)}</td>
				<td>
					<button class="edit-db" data-index="${index}">✏️</button>
					<button class="delete-db" data-index="${index}">🗑️</button>
				</td>
			`;
			tbody.appendChild(row);
		});

		table.appendChild(tbody);
		container.appendChild(table);

		// Обработчики кнопок
		document.querySelectorAll('.edit-db').forEach(btn => {
			btn.addEventListener('click', function() {
				editDatabase(parseInt(this.dataset.index));
			});
		});

		document.querySelectorAll('.delete-db').forEach(btn => {
			btn.addEventListener('click', function() {
				deleteDatabase(parseInt(this.dataset.index));
			});
		});
	}

	function editDatabase(index) {
		const db = databases[index];
		document.getElementById('db-name').value = db.name;
		document.getElementById('db-id').value = db.id;
		document.getElementById('db-url').value = db.url;
		
		document.getElementById('database-form').style.display = 'block';
		editingIndex = index;
	}

	function deleteDatabase(index) {
		if (!confirm('Вы уверены что хотите удалить эту базу?')) {
			return;
		}

		databases.splice(index, 1);
		saveToServer();
		renderDatabases();
	}

	function saveDatabase() {
		const name = document.getElementById('db-name').value.trim();
		const id = document.getElementById('db-id').value.trim();
		const url = document.getElementById('db-url').value.trim();

		if (!name || !id || !url) {
			showStatus('Заполните все поля!', 'error');
			return;
		}

		if (!/^[a-zA-Z0-9_-]+$/.test(id)) {
			showStatus('Идентификатор должен содержать только латинские буквы, цифры, _ и -', 'error');
			return;
		}

		if (!url.startsWith('https://')) {
			showStatus('URL должен начинаться с https://', 'error');
			return;
		}

		const dbData = { name, id, url };

		if (editingIndex >= 0) {
			databases[editingIndex] = dbData;
		} else {
			databases.push(dbData);
		}

		saveToServer();
		document.getElementById('database-form').style.display = 'none';
		clearForm();
	}

	function saveToServer() {
		fetch(apiUrl, {
			method: 'POST',
			credentials: 'include',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(databases)
		})
		.then(response => response.json())
		.then(data => {
			if (data.success) {
				showStatus('Настройки сохранены!', 'success');
				renderDatabases();
			}
		})
		.catch(err => {
			console.error('Error saving:', err);
			showStatus('Ошибка сохранения!', 'error');
		});
	}

	function clearForm() {
		document.getElementById('db-name').value = '';
		document.getElementById('db-id').value = '';
		document.getElementById('db-url').value = '';
	}

	function showStatus(message, type) {
		const status = document.getElementById('save-status');
		status.textContent = message;
		status.style.color = type === 'error' ? '#d93025' : '#188038';
		status.style.padding = '10px';
		status.style.marginTop = '10px';
		status.style.borderRadius = '4px';
		status.style.backgroundColor = type === 'error' ? '#fce8e6' : '#e6f4ea';
		
		setTimeout(() => {
			status.textContent = '';
		}, 5000);
	}

	function escapeHtml(text) {
		const div = document.createElement('div');
		div.textContent = text;
		return div.innerHTML;
	}
})();
</script>

<style>
.section h2 {
	margin-bottom: 10px;
}
.settings-hint {
	color: #666;
	margin-bottom: 20px;
}
.grid {
	border-collapse: collapse;
	width: 100%;
}
.grid th, .grid td {
	padding: 10px;
	text-align: left;
	border-bottom: 1px solid #ddd;
}
.grid th {
	background: #f5f5f5;
	font-weight: 600;
}
.grid tr:hover {
	background: #f9f9f9;
}
input[type="text"],
input[type="url"] {
	padding: 8px;
	border: 1px solid #ccc;
	border-radius: 4px;
	font-size: 14px;
}
button {
	padding: 10px 20px;
	border: none;
	border-radius: 4px;
	cursor: pointer;
	font-size: 14px;
	margin-right: 10px;
}
button.primary {
	background: #0082c9;
	color: white;
}
button.primary:hover {
	background: #00679e;
}
#cancel-database {
	background: #ccc;
	color: #333;
}
#cancel-database:hover {
	background: #bbb;
}
</style>
