<?php
/**
 * Dashboard page: service state, resource gauges, quick facts.
 */

function page_dashboard()
{
    $apache = svc_status('Apache24');
    $maria = svc_status('MariaDB');
    $httpOk = is_listening(OZI_HTTP_PORT);
    $mysqlOk = is_listening(OZI_MYSQL_PORT);
    $cpu = sys_cpu();
    $mem = sys_memory();
    $disk = sys_disk();
    $db = db_info();

    $memUsed = ($mem['total_kb'] > 0)
        ? round(100 * ($mem['total_kb'] - $mem['free_kb']) / $mem['total_kb']) : 0;
    $memFreeMb = round($mem['free_kb'] / 1024, 1);
    $diskFreeGb = round($disk['free'] / 1073741824, 1);

    page_header('Dashboard', 'dashboard');

    echo '<div class="cards">';
    echo card_svc('Apache HTTP', $apache, $httpOk);
    echo card_svc('MariaDB', $maria, $mysqlOk);
    echo '</div>';

    echo '<div class="cards">';
    echo '<div class="card"><h3>CPU Load</h3><div class="gauge-wrap">'
       . '<div class="gauge" style="--pct:' . (int)$cpu . '"><div class="gauge-inner">' . (int)$cpu . '%</div></div></div></div>';
    echo '<div class="card"><h3>Memory</h3><div class="gauge-wrap">'
       . '<div class="gauge" style="--pct:' . (int)$memUsed . '"><div class="gauge-inner">' . (int)$memUsed . '%</div></div></div>'
       . '<p class="sub">' . $memFreeMb . ' MB free</p></div>';
    echo '<div class="card"><h3>Disk (' . e(substr(OZI_INSTALL, 0, 2)) . ')</h3><div class="gauge-wrap">'
       . '<div class="gauge" style="--pct:' . (int)$disk['free_pct'] . '"><div class="gauge-inner">' . (int)$disk['free_pct'] . '%</div></div></div>'
       . '<p class="sub">' . $diskFreeGb . ' GB free</p></div>';
    echo '</div>';

    echo '<div class="cards">';
    echo '<div class="card"><h3>Database</h3><ul class="facts">';
    echo '<li>Name: <b>' . e(OZI_DB_NAME) . '</b></li>';
    if ($db['ok']) {
        echo '<li>Size: <b>' . e($db['size_mb']) . ' MB</b></li>';
        echo '<li>Tables: <b>' . (int)$db['tables'] . '</b></li>';
    } else {
        echo '<li class="bad">' . e($db['error']) . '</li>';
    }
    echo '</ul></div>';
    echo '<div class="card"><h3>Quick actions</h3><div class="quick">';
    echo '<a class="btn" href="index.php?p=services">Manage services</a>';
    echo '<a class="btn" href="index.php?p=backup">Backup now</a>';
    echo '<a class="btn" href="index.php?p=health">Run health check</a>';
    echo '</div></div>';
    echo '</div>';

    page_footer();
}

function card_svc($label, $state, $listening)
{
    $st = $state === 'running' ? 'running' : 'stopped';
    $stateLabel = ($state === 'running') ? 'RUNNING' : strtoupper($state);
    $portOk = $listening ? 'listening' : 'closed';
    $portLabel = $listening ? 'Port open' : 'Port closed';
    $bad = ($state !== 'running');
    return '<div class="card svc"><h3>' . e($label) . '</h3>'
        . '<div class="dot ' . $st . '"></div>'
        . '<p class="state ' . ($bad ? 'bad' : 'good') . '">' . e($stateLabel) . '</p>'
        . '<p class="sub ' . ($listening ? 'good' : 'bad') . '">' . e($portLabel) . '</p></div>';
}
