<?php
/**
 * OZI-RIS Server Pack - Live status JSON endpoint.
 * Authenticated lightweight poll target for the top-bar status pill.
 * Returns: {"ok":true,"apache":"running","maria":"running","http":true,
 *           "mysql":true,"overall":"ok","cpu":5,"uptime":"3d 04h ..."}
 */
require_once __DIR__ . '\lib\bootstrap.php';
require_once __DIR__ . '\lib\auth.php';
auth_require();
require_once __DIR__ . '\lib\system.php';

http_headers();
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$apache = svc_status('Apache24');
$maria  = svc_status('MariaDB');
$http   = is_listening(OZI_HTTP_PORT);
$mysql  = is_listening(OZI_MYSQL_PORT);

$bad = ($apache !== 'running' || $maria !== 'running' || !$http || !$mysql);
$warn = (!$bad && (int)sys_cpu() >= 90);

$data = array(
    'ok'      => true,
    'apache'  => $apache,
    'maria'   => $maria,
    'http'    => $http,
    'mysql'   => $mysql,
    'overall' => $bad ? 'bad' : ($warn ? 'warn' : 'ok'),
    'cpu'     => (int)sys_cpu(),
    'uptime'  => sys_uptime(),
);
echo json_encode($data);
exit;
