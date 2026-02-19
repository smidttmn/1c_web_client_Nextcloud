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

namespace OCA\OneCWebClient\Controller;

use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\JSONResponse;
use OCP\IRequest;
use OCP\IConfig;
use OCP\IL10N;

class ConfigController extends Controller {

	private IConfig $config;
	private IL10N $l10n;

	public function __construct(
		string $AppName,
		IRequest $request,
		IConfig $config,
		IL10N $l10n
	) {
		parent::__construct($AppName, $request);
		$this->config = $config;
		$this->l10n = $l10n;
	}

	/**
	 * @NoAdminRequired
	 */
	public function saveConfig(string $databases = null): JSONResponse {
		try {
			if ($databases !== null) {
				// Проверяем формат данных
				$dbArray = json_decode($databases, true);
				
				if (json_last_error() !== JSON_ERROR_NONE) {
					return new JSONResponse([
						'status' => 'error',
						'message' => $this->l10n->t('Invalid JSON format')
					], 400);
				}
				
				// Валидация данных
				foreach ($dbArray as $db) {
					if (!isset($db['name']) || !isset($db['url']) || empty($db['name']) || empty($db['url'])) {
						return new JSONResponse([
							'status' => 'error',
							'message' => $this->l10n->t('Each database must have a name and URL')
						], 400);
					}
					
					// Проверяем формат URL
					if (!filter_var($db['url'], FILTER_VALIDATE_URL)) {
						return new JSONResponse([
							'status' => 'error',
							'message' => $this->l10n->t('Invalid URL format: ') . $db['url']
						], 400);
					}
				}
				
				$this->config->setAppValue('one_c_web_client', 'databases', json_encode($dbArray));
			}

			return new JSONResponse(['status' => 'success']);
		} catch (\Exception $e) {
			return new JSONResponse([
				'status' => 'error',
				'message' => $e->getMessage()
			], 500);
		}
	}
}