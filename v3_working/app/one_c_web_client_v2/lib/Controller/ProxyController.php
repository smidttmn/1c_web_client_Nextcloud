<?php

declare(strict_types=1);

namespace OCA\OneCWebClientV2\Controller;

use OCP\AppFramework\Controller;
use OCP\AppFramework\Http;
use OCP\AppFramework\Http\Response;
use OCP\IRequest;
use OCP\IUserSession;

/**
 * @NoCSRFRequired
 * @NoAdminRequired
 */
class ProxyController extends Controller {

	/** @var IUserSession */
	private $userSession;

	public function __construct(string $appName, IRequest $request, IUserSession $userSession) {
		parent::__construct($appName, $request);
		$this->userSession = $userSession;
	}

	/**
	 * Проксирует GET запросы к 1С только для авторизованных пользователей
	 * @NoCSRFRequired
	 * @NoAdminRequired
	 */
	public function proxy(string $basePath = '', string $path = ''): Response {
		return $this->proxyRequest($basePath, $path, 'GET');
	}

	/**
	 * Проксирует POST запросы к 1С только для авторизованных пользователей
	 * @NoCSRFRequired
	 * @NoAdminRequired
	 */
	public function proxyPost(string $basePath = '', string $path = ''): Response {
		return $this->proxyRequest($basePath, $path, 'POST');
	}

	/**
	 * Основной метод проксирования
	 */
	private function proxyRequest(string $basePath, string $path, string $method): Response {
		// Проверяем авторизацию
		$user = $this->userSession->getUser();
		if ($user === null) {
			$response = new Response();
			$response->setStatus(Http::STATUS_UNAUTHORIZED);
			$response->addHeader('WWW-Authenticate', 'Session required');
			return $response;
		}

		// Получаем список баз из конфига
		$appConfig = \OC::$server->get(\OCP\IConfig::class);
		$databases = json_decode($appConfig->getAppValue('one_c_web_client_v2', 'databases', '[]'), true) ?? [];
		
		// Ищем базу по ID
		$targetDb = null;
		foreach ($databases as $db) {
			if (isset($db['id']) && $db['id'] === $basePath) {
				$targetDb = $db;
				break;
			}
		}

		if ($targetDb === null) {
			$response = new Response();
			$response->setStatus(Http::STATUS_NOT_FOUND);
			return $response;
		}

		// Формируем URL к 1С
		$oneCUrl = rtrim($targetDb['url'], '/') . '/' . ltrim($path, '/');
		
		// Проксируем запрос
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $oneCUrl);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
		curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
		curl_setopt($ch, CURLOPT_TIMEOUT, 60);
		
		// Копируем заголовки запроса
		$headers = [];
		foreach (getallheaders() as $name => $value) {
			if (strtolower($name) !== 'host') {
				$headers[] = "$name: $value";
			}
		}
		curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
		
		// Для POST/PUT запросов
		if ($_SERVER['REQUEST_METHOD'] === 'POST') {
			curl_setopt($ch, CURLOPT_POST, true);
			curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
		} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
			curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
			curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
		}
		
		$responseBody = curl_exec($ch);
		$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
		$contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
		curl_close($ch);

		// Возвращаем ответ
		$response = new Response();
		$response->setStatus($httpCode);
		$response->setContent($responseBody);
		
		if ($contentType) {
			$response->addHeader('Content-Type', $contentType);
		}
		
		// Добавляем заголовки для 1С
		$response->addHeader('Access-Control-Allow-Origin', '*');
		$response->addHeader('X-Frame-Options', 'SAMEORIGIN');
		
		return $response;
	}
}
