<?php
/**
 * OZI-RIS Server Pack - Admin Panel login.
 * First run: create the admin password (no default password).
 */
require_once __DIR__ . '\lib\bootstrap.php';
require_once __DIR__ . '\lib\auth.php';

$error = '';
$lock = auth_locked();
if ($lock['locked']) {
    $mins = (int)ceil(($lock['until'] - time()) / 60);
    $error = 'Too many failed attempts. Try again in ' . $mins . ' minute(s).';
}

$needsSetup = (ozi_admin('admin_hash', '') === '');

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !$lock['locked']) {
    if ($needsSetup) {
        $u = isset($_POST['user']) ? trim($_POST['user']) : '';
        $p1 = isset($_POST['pass1']) ? $_POST['pass1'] : '';
        $p2 = isset($_POST['pass2']) ? $_POST['pass2'] : '';
        if ($u === '' || strlen($p1) < 8) {
            $error = 'Username required and password must be at least 8 characters.';
        } elseif ($p1 !== $p2) {
            $error = 'Passwords do not match.';
        } elseif (!preg_match('/^[A-Za-z0-9_\-\.]+$/', $u)) {
            $error = 'Username may only contain letters, numbers, _ - .';
        } else {
            $salt = bin2hex(ozi_random_bytes(16));
            $hash = hash('sha256', $salt . $p1);
            $contents = "; OZI-RIS Admin Panel credentials (do not share)\r\n"
                . "admin_user=" . $u . "\r\n"
                . "admin_salt=" . $salt . "\r\n"
                . "admin_hash=" . $hash . "\r\n";
            if (@file_put_contents(OZI_ADMIN_FILE, $contents)) {
                audit('admin account created');
                $needsSetup = false;
                // reload credentials so the login below sees the new hash
                $GLOBALS['OZI_ADMIN'] = cfg_read(OZI_ADMIN_FILE);
                auth_login($u, $p1);
                redirect('index.php');
            } else {
                $error = 'Could not write config\admin.ini. Check permissions.';
            }
        }
    } else {
        $u = isset($_POST['user']) ? trim($_POST['user']) : '';
        $p = isset($_POST['pass']) ? $_POST['pass'] : '';
        if ($u === '' || $p === '') {
            $error = 'Enter username and password.';
        } elseif (auth_login($u, $p)) {
            redirect('index.php');
        } else {
            $error = 'Invalid username or password.';
        }
    }
}

http_headers();
echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8" />';
echo '<title>Sign in - OZI-RIS Admin</title>';
echo '<link rel="stylesheet" href="assets/admin.css" />';
echo '</head><body class="loginbody"><div class="loginwrap">';
echo '<div class="loginbrand"><div>OZI-RIS<small>Server Manager</small></div></div>';
echo '<h2>' . ($needsSetup ? 'Create administrator account' : 'Sign in') . '</h2>';
if ($error) { echo '<div class="alert error">' . e($error) . '</div>'; }
if ($needsSetup) {
    echo '<form method="post" autocomplete="off">';
    echo '<label>Username<input type="text" name="user" maxlength="32" /></label>';
    echo '<label>Password (min 8)<input type="password" name="pass1" /></label>';
    echo '<label>Confirm password<input type="password" name="pass2" /></label>';
    echo '<button type="submit">Create account</button></form>';
} else {
    echo '<form method="post" autocomplete="off">';
    echo '<label>Username<input type="text" name="user" autofocus /></label>';
    echo '<label>Password<input type="password" name="pass" /></label>';
    echo '<button type="submit">Sign in</button></form>';
}
echo '<p class="loginfoot">Intranet administration panel &mdash; local network only.</p>';
echo '</div></body></html>';
