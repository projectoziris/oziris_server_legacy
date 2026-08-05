<?php
/**
 * OZI-RIS Server Pack - Admin Panel layout helpers.
 */

function page_header($title, $active)
{
    $nav = array(
        'dashboard' => 'Dashboard',
        'services'  => 'Services',
        'health'    => 'Health Check',
        'system'    => 'System',
        'network'   => 'Network',
        'processes' => 'Processes',
        'backup'    => 'Backup',
        'logs'      => 'Logs',
        'settings'  => 'Settings',
    );
    http_headers();
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8" />';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1" />';
    echo '<meta name="csrf" content="' . e($_SESSION['csrf']) . '" />';
    echo '<title>' . e($title) . ' - OZI-RIS Server Manager</title>';
    echo '<link rel="stylesheet" href="assets/admin.css" />';
    echo '</head><body>';
    echo '<div class="sidebar">';
    echo '<div class="brand"><div class="brandtxt">OZI-RIS<small>Server Manager</small></div></div>';
    echo '<nav>';
    foreach ($nav as $key => $label) {
        $cls = ($key === $active) ? ' class="active"' : '';
        echo '<a href="index.php?p=' . e($key) . '"' . $cls . '>' . e($label) . '</a>';
    }
    echo '</nav>';
    echo '<div class="sidefoot"><span class="host">' . e(sys_hostname()) . '</span>';
    echo '<span class="hostip" id="hostip"></span>';
    echo '<a href="logout.php" class="logout">Log out</a></div>';
    echo '</div>';
    echo '<div class="main">';
    echo '<div class="topbar"><h1 class="titlewrap">' . e($title) . '</h1>';
    echo '<div class="topright">';
    echo '<span class="statuspill" id="statuspill"><span class="spinner"></span><span id="statuslabel">checking&hellip;</span></span>';
    echo '<button class="iconbtn" id="refreshbtn">Refresh</button>';
    echo '<span class="clock" id="clock"></span>';
    echo '</div></div>';
    echo '<div class="content">';
}

function page_footer()
{
    echo '</div>';
    echo '<div class="footerbar"><span>OZI-RIS Server Manager</span>'
       . '<span>' . e(sys_hostname()) . ' &middot; PHP ' . PHP_VERSION . ' &middot; Intranet</span></div>';
    echo '</div>';
    echo '<script src="assets/admin.js"></script></body></html>';
}

function alert($kind, $msg)
{
    echo '<div class="alert ' . e($kind) . '">' . e($msg) . '</div>';
}
