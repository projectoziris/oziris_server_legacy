<?php
/**
 * OZI-RIS Server Pack - Admin Panel front controller.
 * Route: index.php?p=dashboard|services|backup|health|logs|settings
 */
require_once __DIR__ . '\lib\bootstrap.php';
require_once __DIR__ . '\lib\auth.php';
auth_require();

$pages = array('dashboard', 'services', 'backup', 'health', 'logs', 'settings', 'system', 'network', 'processes');
$p = isset($_GET['p']) ? preg_replace('/[^a-z]/', '', strtolower($_GET['p'])) : 'dashboard';
if (!in_array($p, $pages, true)) { $p = 'dashboard'; }

require_once __DIR__ . '\lib\system.php';
require_once __DIR__ . '\lib\layout.php';
require_once __DIR__ . '\lib\pages\\' . $p . '.php';

call_user_func('page_' . $p);
