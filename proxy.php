<?php
/**
 * Proxy script for 1C WebClient
 * Proxies requests to 1C servers through Nextcloud
 */

// Only allow POST and GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit('Method not allowed');
}

// Get the target URL from the request
$targetUrl = isset($_GET['url']) ? $_GET['url'] : '';

// Validate URL
if (empty($targetUrl)) {
    http_response_code(400);
    exit('URL parameter is required');
}

// Parse and validate the URL
$parsedUrl = parse_url($targetUrl);
if (!$parsedUrl || !isset($parsedUrl['host'])) {
    http_response_code(400);
    exit('Invalid URL');
}

// Only allow internal network addresses (10.x.x.x, 192.168.x.x, 172.16-31.x.x)
$host = $parsedUrl['host'];
if (!preg_match('/^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|localhost)/', $host)) {
    http_response_code(403);
    exit('Access to external URLs is not allowed');
}

// Initialize cURL
$ch = curl_init();

// Set cURL options
curl_setopt($ch, CURLOPT_URL, $targetUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_MAXREDIRS, 5);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // For self-signed certificates
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);

// Forward headers from the original request
$headers = [];
foreach (getallheaders() as $name => $value) {
    if (in_array(strtolower($name), ['accept', 'accept-language', 'accept-encoding'])) {
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
    http_response_code(502);
    exit('Proxy error: ' . curl_error($ch));
}

curl_close($ch);

// Set response headers
http_response_code($httpCode);
if ($contentType) {
    header("Content-Type: $contentType");
}

// Output the response
echo $response;
