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

namespace OCA\OneCWebClientV2\Controller;

use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\TemplateResponse;
use OCP\IRequest;
use OCP\Util;

/**
 * @NoAdminRequired
 * @NoCSRFRequired
 */
class PageController extends Controller {

	public function __construct(string $appName, IRequest $request) {
		parent::__construct($appName, $request);
	}

	/**
	 * @UseSession
	 * @NoCSRFRequired
	 */
	public function index(): TemplateResponse {
		// Подключаем только JS (CSS в index.php)
		Util::addScript('one_c_web_client_v2', 'index');

		$response = new TemplateResponse('one_c_web_client_v2', 'index', [
			'title' => '1C WebClient V2',
		]);
		$response->addHeader('X-Frame-Options', 'SAMEORIGIN');
		return $response;
	}
}
