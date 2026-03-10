<?php

declare(strict_types=1);

namespace OCA\OneCWebClientV2\Controller;

use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\JSONResponse;
use OCP\IConfig;
use OCP\IRequest;

class ConfigController extends Controller {

	/** @var IConfig */
	private $config;

	public function __construct(string $appName, IRequest $request, IConfig $config) {
		parent::__construct($appName, $request);
		$this->config = $config;
	}

	/**
	 * @NoCSRFRequired
	 * @NoAdminRequired
	 */
	public function saveDatabases(): JSONResponse {
		// Получаем JSON из тела запроса
		$json = file_get_contents('php://input');
		$databases = json_decode($json, true);
		
		if (!is_array($databases)) {
			$databases = [];
		}
		
		// Сохраняем в конфиг
		$this->config->setAppValue('one_c_web_client_v2', 'databases', json_encode($databases, JSON_UNESCAPED_UNICODE));
		
		return new JSONResponse(['success' => true]);
	}

	/**
	 * @NoCSRFRequired
	 * @NoAdminRequired
	 */
	public function getDatabases(): JSONResponse {
		$databases = $this->config->getAppValue('one_c_web_client_v2', 'databases', '[]');
		$decoded = json_decode($databases, true);
		return new JSONResponse(is_array($decoded) ? $decoded : []);
	}
}
