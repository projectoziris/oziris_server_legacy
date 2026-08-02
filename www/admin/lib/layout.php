<?php
/**
 * OZI-RIS Server Pack - Admin Panel layout helpers.
 */

function page_header($title, $active)
{
    $nav = array(
        'dashboard' => 'Dashboard',
        'services'  => 'Services',
        'backup'    => 'Backup',
        'health'    => 'Health',
        'logs'      => 'Logs',
        'settings'  => 'Settings',
    );
    http_headers();
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8" />';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1" />';
    echo '<title>' . e($title) . ' - OZI-RIS Admin</title>';
    echo '<link rel="stylesheet" href="assets/admin.css" />';
    echo '</head><body>';
    echo '<div class="sidebar">';
    echo '<div class="brand">OZI-RIS<br /><small>Server Manager</small></div>';
    echo '<nav>';
    foreach ($nav as $key => $label) {
        $cls = ($key === $active) ? ' class="active"' : '';
        echo '<a href="index.php?p=' . e($key) . '"' . $cls . '>' . e($label) . '</a>';
    }
    echo '</nav>';
    echo '<div class="sidefoot"><a href="logout.php" class="logout">Log out</a></div>';
    echo '</div>';
    echo '<div class="main"><div class="topbar"><h1>' . e($title) . '</h1>';
    echo '<span class="clock" id="clock"></span></div><div class="content">';
}

function page_footer()
{
    echo '</div></div>';
    echo '<script src="assets/admin.js"></script></body></html>';
}

function alert($kind, $msg)
{
    echo '<div class="alert ' . e($kind) . '">' . e($msg) . '</div>';
}
