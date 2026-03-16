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
use OCP\AppFramework\Http\TemplateResponse;
use OCP\AppFramework\Http\ContentSecurityPolicy;
use OCP\IRequest;
use OCP\IConfig;
use OCP\IL10N;
use OCP\IURLGenerator;
use OCP\Util;

class PageController extends Controller {

	private IConfig $config;
	private IL10N $l10n;
	private IURLGenerator $urlGenerator;

	public function __construct(
		string $AppName,
		IRequest $request,
		IConfig $config,
		IL10N $l10n,
		IURLGenerator $urlGenerator
	) {
		parent::__construct($AppName, $request);
		$this->config = $config;
		$this->l10n = $l10n;
		$this->urlGenerator = $urlGenerator;
	}

	/**
	 * @NoAdminRequired
	 * @NoCSRFRequired
	 */
	public function index(): TemplateResponse {
		$databasesJson = $this->config->getAppValue('one_c_web_client_v3', 'databases', '[]');
		$databases = json_decode($databasesJson, true) ?: [];

		// Извлекаем только имя и URL для передачи в шаблон
		$dbList = [];
		foreach ($databases as $db) {
			$dbList[] = [
				'name' => $db['name'] ?? 'Unknown',
				'url' => $db['url'] ?? ''
			];
		}

		// Добавляем JavaScript
		Util::addScript('one_c_web_client_v3', 'index');

		$params = [
			'databases' => $dbList,
			'appName' => $this->appName
		];

		$response = new TemplateResponse('one_c_web_client_v3', 'index', $params);

		// CSP: добавляем все 1С серверы из базы
		$csp = new ContentSecurityPolicy();
		foreach ($databases as $db) {
			$url = $db['url'] ?? '';
			if (!empty($url)) {
				// Извлекаем домен из URL
				$parsedUrl = parse_url($url);
				if (isset($parsedUrl['host'])) {
					$domain = $parsedUrl['scheme'] . '://' . $parsedUrl['host'];
					$csp->addAllowedFrameDomain($domain);
					$csp->addAllowedScriptDomain($domain);
					$csp->addAllowedConnectDomain($domain);
				}
			}
		}
		$response->setContentSecurityPolicy($csp);

		return $response;
	}
}