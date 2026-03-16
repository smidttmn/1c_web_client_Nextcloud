<?php
namespace OCA\OneCWebClient\AppInfo;

use OCA\OneCWebClient\Controller\PageController;
use OCA\OneCWebClient\Controller\ConfigController;
use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;
use OCP\IRequest;
use OCP\IConfig;
use OCP\IL10N;
use OCP\IURLGenerator;

class Application extends App implements IBootstrap {
	public const APP_ID = 'one_c_web_client_v3';
	
	public function __construct() {
		parent::__construct(self::APP_ID);
	}
	
	public function register(IRegistrationContext $context): void {
		$context->registerService(PageController::class, function($c) {
			return new PageController(
				$c->get('AppName'),
				$c->get(IRequest::class),
				$c->get(IConfig::class),
				$c->get(IL10N::class),
				$c->get(IURLGenerator::class)
			);
		});
		
		$context->registerService(ConfigController::class, function($c) {
			return new ConfigController(
				$c->get('AppName'),
				$c->get(IRequest::class),
				$c->get(IConfig::class),
				$c->get(IL10N::class)
			);
		});
	}
	
	public function boot(IBootContext $context): void {
	}
}
