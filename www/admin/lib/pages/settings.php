<?php
/**
 * Settings page: edit whitelisted keys in config\server.ini.
 * Rewrites the file in place, preserving comments and order.
 */

function page_settings()
{
    $allowed = array(
        'apache_port'    => 'HTTP port',
        'mysql_port'     => 'MySQL port',
        'db_name'        => 'Database name',
        'db_user'        => 'Database user',
        'db_pass'        => 'Database password',
        'memory_limit'   => 'PHP memory limit',
        'upload_max_size'=> 'PHP upload max size',
        'timezone'       => 'Timezone',
        'backup_retention' => 'Backup retention (days)',
    );

    $saved = null;
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!csrf_ok()) {
            $saved = array('error', 'Invalid CSRF token.');
        } else {
            $new = array();
            foreach ($allowed as $key => $label) {
                $val = isset($_POST[$key]) ? trim($_POST[$key]) : '';
                $new[$key] = $val;
            }
            // light validation
            if (!is_numeric($new['apache_port']) || !is_numeric($new['mysql_port'])) {
                $saved = array('error', 'Ports must be numeric.');
            } elseif (!preg_match('/^[A-Za-z0-9_\/\.\-\+ ]+$/', $new['timezone'])) {
                $saved = array('error', 'Timezone contains invalid characters.');
            } elseif (!preg_match('/^\d+[MG]$/i', $new['memory_limit']) || !preg_match('/^\d+[MG]$/i', $new['upload_max_size'])) {
                $saved = array('error', 'Memory/upload sizes must look like 256M or 128M.');
            } elseif (!is_numeric($new['backup_retention'])) {
                $saved = array('error', 'Backup retention must be numeric.');
            } else {
                $ok = ozi_save_cfg($allowed, $new);
                $saved = $ok
                    ? array('ok', 'Configuration saved. Restart services to apply changes.')
                    : array('error', 'Could not write config\server.ini. Check permissions.');
                if ($ok) { audit('settings saved: ' . implode(',', array_keys($new))); }
            }
        }
    }

    page_header('Settings', 'settings');

    if ($saved) { alert($saved[0], $saved[1]); }

    $cfg = cfg_read(OZI_CFG_FILE);

    echo '<div class="card"><h3>Server configuration</h3>';
    echo '<form method="post">' . csrf_field() . '<table class="grid formgrid">';
    foreach ($allowed as $key => $label) {
        $val = isset($cfg[$key]) ? $cfg[$key] : '';
        if ($key === 'db_pass') {
            echo '<tr><th><label for="' . e($key) . '">' . e($label) . '</label></th>'
               . '<td><input type="password" id="' . e($key) . '" name="' . e($key) . '" value="' . e($val) . '" /></td></tr>';
        } else {
            echo '<tr><th><label for="' . e($key) . '">' . e($label) . '</label></th>'
               . '<td><input type="text" id="' . e($key) . '" name="' . e($key) . '" value="' . e($val) . '" /></td></tr>';
        }
    }
    echo '</table>';
    echo '<button class="btn primary" onclick="return confirm(\'Save configuration?\');">Save configuration</button>';
    echo '</form>';
    echo '<p class="sub">Changes to ports or PHP limits require a service restart. The file '
       . 'config\server.ini is the single source of truth.</p>';
    echo '</div>';

    page_footer();
}

/**
 * Rewrite server.ini keeping comments/order, updating allowed keys.
 */
function ozi_save_cfg($allowed, $new)
{
    $lines = file(OZI_CFG_FILE);
    if ($lines === false) { return false; }
    $outLines = array();
    foreach ($lines as $line) {
        $trim = trim($line);
        $written = false;
        foreach ($allowed as $key => $label) {
            $re = '/^' . preg_quote($key, '/') . '\s*=/';
            if (preg_match($re, $trim)) {
                $outLines[] = $key . '=' . $new[$key] . "\r\n";
                unset($allowed[$key]);
                $written = true;
                break;
            }
        }
        if (!$written) { $outLines[] = $line; }
    }
    foreach ($allowed as $key => $label) {
        $outLines[] = $key . '=' . $new[$key] . "\r\n";
    }
    $tmp = OZI_CFG_FILE . '.tmp';
    $ok = @file_put_contents($tmp, implode('', $outLines));
    if ($ok === false) { return false; }
    if (!@rename($tmp, OZI_CFG_FILE)) {
        @unlink($tmp);
        return false;
    }
    return true;
}
