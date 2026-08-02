<?php
/**
 * Logs page: browse files in logs\ and tail the selected one.
 */

function page_logs()
{
    $logs = array();
    foreach (glob(OZI_LOG_DIR . '\*.log') ?: array() as $f) {
        $logs[] = array('name' => basename($f), 'size' => filesize($f), 'mtime' => filemtime($f));
    }
    usort($logs, function ($a, $b) { return $b['mtime'] - $a['mtime']; });

    $selected = isset($_GET['f']) ? basename($_GET['f']) : (isset($logs[0]) ? $logs[0]['name'] : '');
    $content = '';
    if ($selected !== '' && file_exists(OZI_LOG_DIR . '\\' . $selected)) {
        $content = file_get_contents(OZI_LOG_DIR . '\\' . $selected);
    }

    page_header('Logs', 'logs');

    echo '<div class="cards">';
    echo '<div class="card"><h3>Log files</h3>';
    if (!$logs) {
        echo '<p class="sub">No log files yet.</p>';
    } else {
        echo '<ul class="loglist">';
        foreach ($logs as $l) {
            $cls = ($l['name'] === $selected) ? ' class="active"' : '';
            echo '<li' . $cls . '><a href="index.php?p=logs&f=' . urlencode($l['name']) . '">' . e($l['name']) . '</a>'
               . '<span class="sub"> ' . e(round($l['size'] / 1024, 1)) . ' KB</span></li>';
        }
        echo '</ul>';
    }
    echo '</div>';

    echo '<div class="card grow"><h3>' . ($selected !== '' ? e($selected) : 'Log') . '</h3>';
    if ($content !== '') {
        $lines = explode("\n", $content);
        $lines = array_slice($lines, -300);
        echo '<pre class="cmdout">';
        foreach ($lines as $l) { echo e(rtrim($l)) . "\n"; }
        echo '</pre>';
    } else {
        echo '<p class="sub">No content.</p>';
    }
    echo '</div></div>';

    page_footer();
}
