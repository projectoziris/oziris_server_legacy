<?php
/**
 * OZI-RIS Server Pack - lightweight health endpoint.
 * Returns JSON. Used by health_check.cmd.
 */
header('Content-Type: application/json');
header('Cache-Control: no-store');

$result = array(
    'status'   => 'healthy',
    'php'      => PHP_VERSION,
    'mysqli'   => extension_loaded('mysqli'),
    'time'     => date('c'),
);

if (!$result['mysqli']) {
    $result['status'] = 'critical';
}

echo json_encode($result);
