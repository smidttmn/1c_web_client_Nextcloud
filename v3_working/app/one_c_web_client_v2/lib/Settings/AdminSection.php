<?php

declare(strict_types=1);

namespace OCA\OneCWebClientV2\Settings;

use OCP\IL10N;
use OCP\IURLGenerator;
use OCP\Settings\IIconSection;

class AdminSection implements IIconSection {

	public function __construct(
		private IURLGenerator $url,
		private IL10N $l,
	) {
	}

	public function getID(): string {
		return 'one_c_web_client_v2';
	}

	public function getName(): string {
		return $this->l->t('1С:Предприятие');
	}

	public function getPriority(): int {
		return 100;
	}

	public function getIcon(): string {
		return $this->url->imagePath('one_c_web_client_v2', 'app-dark.svg');
	}
}
