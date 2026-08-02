<?php
/**
 * OZI-RIS Server Pack - Admin Panel authentication.
 * Session-based login with lockout. Credentials stored hashed
 * in config\admin.ini (sha256 + salt). No default password:
 * first run forces a setup form.
 */

define('OZI_LOCK_FILE', OZI_LOG_DIR . '\admin_lock.json');
define('OZI_MAX_FAILS', 5);
define('OZI_LOCK_MINUTES', 5);
define('OZI_SESSION_TIMEOUT', 1800); // seconds

function auth_locked()
{
    if (!file_exists(OZI_LOCK_FILE)) { return array('locked' => false); }
    $data = @json_decode(@file_get_contents(OZI_LOCK_FILE), true);
    if (!is_array($data)) { return array('locked' => false); }
    $ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
    if (isset($data['ip']) && $data['ip'] === $ip
        && isset($data['until']) && $data['until'] > time()) {
        return array('locked' => true, 'until' => $data['until']);
    }
    return array('locked' => false);
}

function auth_fail()
{
    $ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
    $data = @json_decode(@file_get_contents(OZI_LOCK_FILE), true);
    if (!is_array($data)) { $data = array(); }
    if (isset($data['ip']) && $data['ip'] !== $ip) { $data = array(); }
    $fails = isset($data['fails']) ? (int)$data['fails'] + 1 : 1;
    $data['ip'] = $ip;
    $data['fails'] = $fails;
    if ($fails >= OZI_MAX_FAILS) {
        $data['until'] = time() + OZI_LOCK_MINUTES * 60;
        $data['fails'] = 0;
    }
    @file_put_contents(OZI_LOCK_FILE, json_encode($data));
}

function auth_clear_fails()
{
    @unlink(OZI_LOCK_FILE);
}

function ozi_hash_equals($a, $b)
{
    if (function_exists('hash_equals')) { return hash_equals($a, $b); }
    if (!is_string($a) || !is_string($b) || strlen($a) !== strlen($b)) { return false; }
    $diff = 0;
    $len = strlen($a);
    for ($i = 0; $i < $len; $i++) { $diff |= ord($a[$i]) ^ ord($b[$i]); }
    return $diff === 0;
}

function auth_verify($user, $pass)
{
    $storedUser = ozi_admin('admin_user', 'admin');
    $salt = ozi_admin('admin_salt', '');
    $hash = ozi_admin('admin_hash', '');
    if ($hash === '' || $salt === '') { return false; }
    if (!ozi_hash_equals($storedUser, $user)) { return false; }
    $computed = hash('sha256', $salt . $pass);
    return ozi_hash_equals($hash, $computed);
}

function auth_login($user, $pass)
{
    if (auth_verify($user, $pass)) {
        session_regenerate_id(true);
        $_SESSION['admin_user'] = $user;
        $_SESSION['login_time'] = time();
        auth_clear_fails();
        audit('login ok');
        return true;
    }
    auth_fail();
    audit('login failed: ' . $user);
    return false;
}

function auth_check()
{
    if (empty($_SESSION['admin_user'])) { return false; }
    if (time() - $_SESSION['login_time'] > OZI_SESSION_TIMEOUT) {
        auth_logout();
        return false;
    }
    $_SESSION['login_time'] = time();
    return true;
}

function auth_require()
{
    if (!auth_check()) { redirect('login.php'); }
}

function auth_logout()
{
    $user = isset($_SESSION['admin_user']) ? $_SESSION['admin_user'] : '?';
    audit('logout: ' . $user);
    $_SESSION = array();
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
}
