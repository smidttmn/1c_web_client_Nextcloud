<?php

declare(strict_types=1);

namespace OCA\OneCWebClientV2\Settings;

use OCP\AppFramework\Http\TemplateResponse;
use OCP\IConfig;
use OCP\Settings\ISettings;

class AdminSettings implements ISettings {

	/** @var IConfig */
	private $config;

	public function __construct(IConfig $config) {
		$this->config = $config;
	}

	public function getForm(): TemplateResponse {
		$databases = $this->config->getAppValue('one_c_web_client_v2', 'databases', '[]');
		$databases = json_decode($databases, true) ?? [];

		return new TemplateResponse('one_c_web_client_v2', 'admin_settings', [
			'databases' => $databases,
		], 'blank');
	}

	public function getSection(): string {
		return 'one_c_web_client_v2';
	}

	public function getPriority(): int {
		return 100;
	}
}
