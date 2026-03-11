<?php
/**
 * @copyright Copyright (c) 2026, Nextcloud GmbH
 *
 * @license GNU AGPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace OCA\OneCWebClient\Settings;

use OCP\AppFramework\Http\TemplateResponse;
use OCP\IConfig;
use OCP\Settings\ISettings;
use OCP\Util;

class AdminSettings implements ISettings {

	public function __construct(
		private IConfig $config
	) {
	}

	public function getForm(): TemplateResponse {
		$dbs = $this->config->getAppValue('one_c_web_client', 'databases', '[]');
		$databases = json_decode($dbs, true) ?: [];

		// Добавляем JavaScript с правильным nonce через Util
		Util::addScript('one_c_web_client', 'admin_settings');

		$params = [
			'databases' => $databases
		];

		return new TemplateResponse('one_c_web_client', 'admin_settings', $params);
	}

	public function getSection(): string {
		return 'one_c_web_client';
	}

	public function getPriority(): int {
		return 10;
	}
}