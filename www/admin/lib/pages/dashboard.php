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
    $ver = sys_versions();
    $os = sys_os();

    $memUsed = ($mem['total_kb'] > 0)
        ? round(100 * ($mem['total_kb'] - $mem['free_kb']) / $mem['total_kb']) : 0;
    $memFreeMb = round($mem['free_kb'] / 1024, 1);
    $diskFreeGb = round($disk['free'] / 1073741824, 1);

    page_header('Dashboard', 'dashboard');

    echo '<div class="summary">';
    echo '<div class="summary-item"><span class="lbl">Host</span><b>' . e(sys_hostname()) . '</b></div>';
    echo '<div class="summary-item"><span class="lbl">OS</span><b>' . e($os['caption']) . ' (' . e($os['build']) . ')</b></div>';
    echo '<div class="summary-item"><span class="lbl">Uptime</span><b>' . e(sys_uptime()) . '</b></div>';
    echo '<div class="summary-item"><span class="lbl">Stack</span><b>' . e($ver['apache']) . ' &middot; ' . e($ver['php']) . ' &middot; ' . e($ver['mariadb']) . '</b></div>';
    echo '</div>';

    echo '<div class="cards">';
    echo card_svc('Apache HTTP', $apache, $httpOk);
    echo card_svc('MariaDB', $maria, $mysqlOk);
    echo '</div>';

    echo '<div class="cards">';
    echo metric_card('CPU Load', (int)$cpu . '%', 'Current utilization', meter_class((int)$cpu), (int)$cpu);
    echo metric_card('Memory', (int)$memUsed . '% used', $memFreeMb . ' MB free of ' . round($mem['total_kb'] / 1024, 1) . ' GB', meter_class((int)$memUsed), (int)$memUsed);
    echo metric_card('Disk (' . e(substr(OZI_INSTALL, 0, 2)) . ')', $diskFreeGb . ' GB free', round($disk['total'] / 1073741824, 1) . ' GB total', meter_class(100 - (int)$disk['free_pct']), 100 - (int)$disk['free_pct']);
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

function metric_card($label, $value, $detail, $cls, $pct)
{
    return '<div class="card"><h3>' . e($label) . '</h3>'
        . '<div class="metric"><div class="metric-val">' . e($value) . '</div>'
        . '<div class="metric-lbl">' . e($detail) . '</div></div>'
        . '<div class="meter ' . $cls . '"><div class="meter-fill" style="width:' . (int)$pct . '%"></div></div></div>';
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
