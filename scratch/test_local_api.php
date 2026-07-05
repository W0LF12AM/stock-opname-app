<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['PHP_AUTH_USER'] = 'admin';
$_SERVER['PHP_AUTH_PW'] = 'admin';
$_GET['vessel_id'] = 21; // TB. SRIKANDI BARUNA 2402

// Capture output
ob_start();
include 'c:/xampp/htdocs/inventory_kapal/api/inventory.php';
$output = ob_get_clean();

echo "Local API Status Code: " . http_response_code() . "\n";
echo "Local API Output Length: " . strlen($output) . "\n";
echo "Local API Output Snippet:\n";
echo substr($output, 0, 500) . "\n";
