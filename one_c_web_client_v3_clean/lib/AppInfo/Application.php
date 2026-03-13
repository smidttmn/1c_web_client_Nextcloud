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

namespace OCA\OneCWebClient\AppInfo;

use OCA\OneCWebClient\Controller\PageController;
use OCA\OneCWebClient\Controller\ConfigController;
use OCA\OneCWebClient\Settings\AdminSettings;
use OCA\OneCWebClient\Settings\AdminSection;
use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;
use OCP\IServerContainer;
use OCP\IRequest;
use OCP\IConfig;
use OCP\IL10N;
use OCP\IURLGenerator;

class Application extends App implements IBootstrap {
	public const APP_ID = 'one_c_web_client';

	public function __construct() {
		parent::__construct(self::APP_ID);
	}

	public function register(IRegistrationContext $context): void {
		// Регистрируем контроллеры
		$context->registerService(PageController::class, function(IServerContainer $c) {
			return new PageController(
				$this->getAppName(),
				$c->get(IRequest::class),
				$c->get(IConfig::class),
				$c->get(IL10N::class),
				$c->get(IURLGenerator::class)
			);
		});

		$context->registerService(ConfigController::class, function(IServerContainer $c) {
			return new ConfigController(
				$this->getAppName(),
				$c->get(IRequest::class),
				$c->get(IConfig::class),
				$c->get(IL10N::class)
			);
		});

		// Регистрируем настройки админки
		$context->registerAdminSettings(AdminSettings::class);
		$context->registerAdminSection(AdminSection::class);
	}

	public function boot(IBootContext $context): void {
		// Загрузка приложения
	}
}
