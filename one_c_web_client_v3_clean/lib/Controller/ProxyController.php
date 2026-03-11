<?php
/**
 * Proxy controller for 1C WebClient
 * Proxies requests to internal 1C servers through Nextcloud
 */

namespace OCA\OneCWebClient\Controller;

use OCP\AppFramework\Controller;
use OCP\AppFramework\Http;
use OCP\AppFramework\Http\DataDisplayResponse;
use OCP\IRequest;
use OCP\IConfig;

class ProxyController extends Controller {

	private IConfig $config;

	public function __construct(
		string $AppName,
		IRequest $request,
		IConfig $config
	) {
		parent::__construct($AppName, $request);
		$this->config = $config;
	}

	/**
	 * @NoAdminRequired
	 * @NoCSRFRequired
	 * @PublicPage
	 */
	public function proxy(string $url = '', string $path = ''): DataDisplayResponse {
		// Get URL from path if not provided directly
		if (empty($url) && !empty($path)) {
			$url = urldecode($path);
		}

		// Validate URL
		if (empty($url)) {
			return new DataDisplayResponse('URL parameter is required', Http::STATUS_BAD_REQUEST);
		}

		// Parse and validate the URL
		$parsedUrl = parse_url($url);
		if (!$parsedUrl || !isset($parsedUrl['host'])) {
			return new DataDisplayResponse('Invalid URL', Http::STATUS_BAD_REQUEST);
		}

		// Only allow internal network addresses
		$host = $parsedUrl['host'];
		if (!preg_match('/^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|localhost)/', $host)) {
			return new DataDisplayResponse('Access to external URLs is not allowed', Http::STATUS_FORBIDDEN);
		}

		// Initialize cURL
		$ch = curl_init();

		// Set cURL options
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
		curl_setopt($ch, CURLOPT_MAXREDIRS, 5);
		curl_setopt($ch, CURLOPT_TIMEOUT, 60);
		curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
		curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
		curl_setopt($ch, CURLOPT_ENCODING, '');

		// Forward some headers
		$headers = [];
		foreach (getallheaders() as $name => $value) {
			if (in_array(strtolower($name), ['accept', 'accept-language', 'accept-encoding', 'user-agent'])) {
				$headers[] = "$name: $value";
			}
		}
		curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

		// Handle POST data
		if ($_SERVER['REQUEST_METHOD'] === 'POST') {
			curl_setopt($ch, CURLOPT_POST, true);
			curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
		}

		// Execute the request
		$response = curl_exec($ch);
		$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
		$contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);

		// Check for errors
		if ($response === false) {
			$error = curl_error($ch);
			curl_close($ch);
			return new DataDisplayResponse('Proxy error: ' . $error, Http::STATUS_BAD_GATEWAY);
		}

		curl_close($ch);

		// Process HTML content to rewrite URLs
		if (strpos($contentType, 'text/html') !== false && !empty($response)) {
			$response = $this->rewriteHtmlUrls($response, $url);
		}

		// Create response
		$dataResponse = new DataDisplayResponse($response, $httpCode);
		if ($contentType) {
			$dataResponse->addHeader('Content-Type', $contentType);
		}
		
		// Add CORS headers for iframe
		$dataResponse->addHeader('Access-Control-Allow-Origin', '*');
		$dataResponse->addHeader('X-Frame-Options', 'SAMEORIGIN');
		
		// Allow mixed content for internal 1C servers
		$dataResponse->addHeader('Content-Security-Policy', "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:; script-src * 'unsafe-inline' 'unsafe-eval'; connect-src * http: https:; frame-src *; img-src * data: blob:; style-src * 'unsafe-inline';");

		return $dataResponse;
	}

	/**
	 * Rewrite URLs in HTML content to use proxy
	 */
	private function rewriteHtmlUrls(string $html, string $baseUrl): string {
		$parsedUrl = parse_url($baseUrl);
		$baseProtocol = $parsedUrl['scheme'] ?? 'http';
		$baseHost = $parsedUrl['host'];
		$basePath = dirname($parsedUrl['path'] ?? '/');

		// Create proxy URL prefix manually
		$proxyPrefix = '/index.php/apps/one_c_web_client/proxy';

		// Rewrite src and href attributes
		$html = preg_replace_callback(
			'/(src|href)\s*=\s*["\']([^"\']+)["\']/i',
			function($matches) use ($proxyPrefix, $baseProtocol, $baseHost, $basePath) {
				$attr = $matches[1];
				$url = $matches[2];

				// Skip data: URLs, javascript:, mailto:, tel:, etc.
				if (preg_match('/^(data:|javascript:|mailto:|tel:|#)/i', $url)) {
					return $matches[0];
				}

				// Convert relative URLs to absolute
				if (strpos($url, '/') === 0) {
					// Absolute path
					$absoluteUrl = $baseProtocol . '://' . $baseHost . $url;
				} elseif (strpos($url, 'http') === 0) {
					// Already absolute
					$absoluteUrl = $url;
				} else {
					// Relative path
					$absoluteUrl = $baseProtocol . '://' . $baseHost . $basePath . '/' . $url;
				}

				// Wrap in proxy URL
				$proxiedUrl = $proxyPrefix . '?url=' . urlencode($absoluteUrl);
				
				return $attr . '="' . $proxiedUrl . '"';
			},
			$html
		);

		// Add base tag to handle any remaining relative URLs
		if (strpos($html, '<head>') !== false) {
			$baseTag = '<base href="' . htmlspecialchars($baseUrl) . '">';
			$html = str_replace('<head>', '<head>' . $baseTag, $html);
		}

		return $html;
	}
}
