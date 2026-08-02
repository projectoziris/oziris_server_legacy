<?php
/**
 * Services page: start / stop / restart Apache24 and MariaDB.
 * Actions POST with CSRF; results are shown inline.
 */

function page_services()
{
    $result = null;

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!csrf_ok()) {
            $result = array('error', 'Invalid CSRF token. Try again.');
        } else {
            $name = isset($_POST['svc']) ? $_POST['svc'] : '';
            $action = isset($_POST['action']) ? $_POST['action'] : '';
            if (!in_array($name, ozi_services(), true)
                || !in_array($action, array('start', 'stop', 'restart'), true)) {
                $result = array('error', 'Invalid request.');
            } else {
                audit('service ' . $action . ' ' . $name);
                list($rc, $lines) = svc_action($name, $action);
                $tail = array_slice(array_filter($lines, 'strlen'), -4);
                $result = array(
                    $rc === 0 ? 'ok' : 'error',
                    ($rc === 0 ? 'Command accepted.' : 'Command returned an error.') . ' ' . $name . ' -> ' . $action,
                    $tail,
                );
            }
        }
    }

    page_header('Services', 'services');

    if ($result) {
        $kind = $result[0];
        alert($kind, $result[1]);
        if (isset($result[2]) && $result[2]) {
            echo '<pre class="cmdout">';
            foreach ($result[2] as $l) { echo e($l) . "\n"; }
            echo '</pre>';
        }
    }

    foreach (ozi_services() as $svc) {
        $state = svc_status($svc);
        $running = ($state === 'running');
        $desc = '';
        if ($svc === 'Apache24') { $desc = 'Web server - HTTP port ' . OZI_HTTP_PORT; }
        if ($svc === 'MariaDB') { $desc = 'Database server - MySQL port ' . OZI_MYSQL_PORT; }
        echo '<div class="card svc-row">';
        echo '<div><h3>' . e($svc) . '</h3><p class="sub">' . e($desc) . '</p></div>';
        echo '<div class="dot ' . ($running ? 'running' : 'stopped') . '"></div>';
        echo '<span class="state ' . ($running ? 'good' : 'bad') . '">' . e(strtoupper($state)) . '</span>';
        echo '<div class="btns">';
        echo '<form method="post" class="inline"><input type="hidden" name="svc" value="' . e($svc) . '" />'
           . '<input type="hidden" name="action" value="start" />' . csrf_field()
           . '<button class="btn" ' . ($running ? 'disabled' : '') . '>Start</button></form>';
        echo '<form method="post" class="inline"><input type="hidden" name="svc" value="' . e($svc) . '" />'
           . '<input type="hidden" name="action" value="stop" />' . csrf_field()
           . '<button class="btn danger" ' . ($running ? '' : 'disabled') . '>Stop</button></form>';
        echo '<form method="post" class="inline" onsubmit="return confirm(\'Restart ' . e($svc) . '?\');">'
           . '<input type="hidden" name="svc" value="' . e($svc) . '" />'
           . '<input type="hidden" name="action" value="restart" />' . csrf_field()
           . '<button class="btn" ' . ($running ? '' : 'disabled') . '>Restart</button></form>';
        echo '</div></div>';
    }

    page_footer();
}
