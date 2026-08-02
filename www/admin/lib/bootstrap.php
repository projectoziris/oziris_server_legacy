<?php
/**
 * OZI-RIS Server Pack - Admin Panel bootstrap.
 * Loads configuration, starts the session, and defines shared helpers.
 * Every admin page must include this file first.
 *
 * Path resolution: the panel is served from the install web root
 * (<install>\www\admin) while configuration, scripts and logs live in
 * the pack root. The pack root is located by probing for the signature
 * file config\server.ini next to scripts\common.cmd.
 */

error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE);
ini_set('display_errors', '0');
date_default_timezone_set('Asia/Kuala_Lumpur');

/* ---------------------------------------------------------- pack root */
$selfDir = __DIR__;                       // <pack-or-install>\www\admin\lib
$upRoot = realpath($selfDir . '\..\..\..'); // <pack-or-install>
$candidates = array();
if ($upRoot) { $candidates[] = $upRoot; }
$candidates[] = 'C:\oziris_server';       // fallback for this deployment

define('OZI_ROOT', ozi_resolve_root($candidates));

function ozi_resolve_root($candidates)
{
    foreach ($candidates as $c) {
        if (is_dir($c)
            && file_exists($c . '\config\server.ini')
            && is_dir($c . '\scripts')) {
            return rtrim($c, '\\/');
        }
    }
    return rtrim($candidates[0], '\\/');
}

define('OZI_CFG_FILE', OZI_ROOT . '\config\server.ini');
define('OZI_ADMIN_FILE', OZI_ROOT . '\config\admin.ini');
define('OZI_SCRIPTS', OZI_ROOT . '\scripts');
define('OZI_LOG_DIR', OZI_ROOT . '\logs');
define('OZI_ADMIN_LOG', OZI_LOG_DIR . '\admin_panel.log');
define('OZI_JOBS_DIR', OZI_LOG_DIR . '\jobs');

if (!is_dir(OZI_LOG_DIR)) { @mkdir(OZI_LOG_DIR, 0777, true); }
if (!is_dir(OZI_JOBS_DIR)) { @mkdir(OZI_JOBS_DIR, 0777, true); }

/* ---------------------------------------------------------- config load */
function cfg_read($file)
{
    $cfg = array();
    $lines = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($lines === false) { return $cfg; }
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === ';' || $line[0] === '#') { continue; }
        if ($line[0] === '[') { continue; }
        $pos = strpos($line, '=');
        if ($pos === false) { continue; }
        $cfg[trim(substr($line, 0, $pos))] = trim(substr($line, $pos + 1));
    }
    return $cfg;
}

$OZI_CFG = cfg_read(OZI_CFG_FILE);
$OZI_ADMIN = cfg_read(OZI_ADMIN_FILE);

function ozi_cfg($key, $default = '')
{
    global $OZI_CFG;
    return isset($OZI_CFG[$key]) ? $OZI_CFG[$key] : $default;
}
function ozi_admin($key, $default = '')
{
    global $OZI_ADMIN;
    return isset($OZI_ADMIN[$key]) ? $OZI_ADMIN[$key] : $default;
}

define('OZI_INSTALL', ozi_cfg('install_path', 'C:\OZI-RIS-Server'));
define('OZI_HTTP_PORT', ozi_cfg('apache_port', '8000'));
define('OZI_MYSQL_PORT', ozi_cfg('mysql_port', '3306'));
define('OZI_DB_NAME', ozi_cfg('db_name', 'my_db'));
define('OZI_DB_USER', ozi_cfg('db_user', 'root'));
define('OZI_DB_PASS', ozi_cfg('db_pass', ''));
define('OZI_BACKUP_DIR', OZI_INSTALL . '\backup');

/* ---------------------------------------------------------- session */
if (session_status() === PHP_SESSION_NONE) {
    session_name('OZIADMIN');
    session_set_cookie_params(0, '/', '', false, true);
    session_start();
}
if (empty($_SESSION['csrf'])) { $_SESSION['csrf'] = bin2hex(ozi_random_bytes(16)); }

/* ---------------------------------------------------------- helpers */
function ozi_random_bytes($n)
{
    if (function_exists('openssl_random_pseudo_bytes')) {
        $out = openssl_random_pseudo_bytes($n, $crypto);
        if ($crypto && strlen($out) === $n) { return $out; }
    }
    $out = '';
    for ($i = 0; $i < $n; $i++) { $out .= chr(mt_rand(0, 255)); }
    return $out;
}

function e($v)
{
    return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');
}

function csrf_field()
{
    return '<input type="hidden" name="csrf" value="' . e($_SESSION['csrf']) . '" />';
}

function csrf_ok()
{
    return isset($_POST['csrf']) && is_string($_POST['csrf']) && $_POST['csrf'] === $_SESSION['csrf'];
}

function audit($action)
{
    $ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : 'unknown';
    $user = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : '?';
    $line = sprintf("[%s] %s %s %s\n", date('Y-m-d H:i:s'), $user, $ip, $action);
    @file_put_contents(OZI_ADMIN_LOG, $line, FILE_APPEND);
}

function http_headers()
{
    header('X-Frame-Options: DENY');
    header('X-Content-Type-Options: nosniff');
    header('Cache-Control: no-store');
}

function redirect($url)
{
    header('Location: ' . $url);
    exit;
}

function run_shell($cmd, &$out = array())
{
    $rc = 0;
    exec($cmd . ' 2>&1', $out, $rc);
    return $rc;
}
