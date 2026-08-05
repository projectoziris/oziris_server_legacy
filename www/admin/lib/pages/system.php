<?php
/**
 * System page: OS, host, uptime, CPU, RAM, disk, stack versions, hardware.
 */

function page_system()
{
    $os = sys_os();
    $hw = sys_hardware();
    $cpu = sys_cpu_detail();
    $mem = sys_memory();
    $disk = sys_disk();
    $ver = sys_versions();

    $memTotal = round($mem['total_kb'] / 1024, 1);
    $memFree = round($mem['free_kb'] / 1024, 1);
    $memUsed = $memTotal - $memFree;

    page_header('System', 'system');

    echo '<div class="cards">';
    echo '<div class="card"><h3>Operating system</h3><ul class="facts">';
    echo '<li>Name: <b>' . e($os['caption']) . '</b></li>';
    echo '<li>Version: <b>' . e($os['version']) . '</b></li>';
    echo '<li>Build: <b>' . e($os['build']) . '</b></li>';
    echo '<li>Architecture: <b>' . e($os['arch']) . '</b></li>';
    echo '</ul></div>';
    echo '<div class="card"><h3>Hardware</h3><ul class="facts">';
    echo '<li>Manufacturer: <b>' . e($hw['manufacturer']) . '</b></li>';
    echo '<li>Model: <b>' . e($hw['model']) . '</b></li>';
    echo '<li>Type: <b>' . e($hw['type']) . '</b></li>';
    echo '</ul></div>';
    echo '<div class="card"><h3>Host</h3><ul class="facts">';
    echo '<li>Hostname: <b>' . e(sys_hostname()) . '</b></li>';
    echo '<li>Up since: <b>' . e(sys_boot_time()) . '</b></li>';
    echo '<li>Uptime: <b>' . e(sys_uptime()) . '</b></li>';
    echo '<li>Web root: <b>' . e(OZI_INSTALL) . '</b></li>';
    echo '</ul></div>';
    echo '</div>';

    $cpuLoad = (int)sys_cpu();
    $memPct = (int)sys_mem_pct($mem);
    $diskPct = 100 - (int)$disk['free_pct'];
    echo '<div class="cards">';
    echo '<div class="card"><h3>CPU</h3><ul class="facts">';
    echo '<li>Model: <b>' . e($cpu['name']) . '</b></li>';
    echo '<li>Cores: <b>' . e($cpu['cores']) . '</b></li>';
    echo '<li>Logical processors: <b>' . e($cpu['threads']) . '</b></li>';
    echo '<li>Max clock: <b>' . e($cpu['speed']) . ' MHz</b></li>';
    echo '</ul>';
    echo '<div class="meter ' . meter_class($cpuLoad) . '"><div class="meter-fill" style="width:' . $cpuLoad . '%"></div></div>'
       . '<p class="sub">Current load: <b>' . $cpuLoad . '%</b></p></div>';
    echo '<div class="card"><h3>Memory</h3><div class="metric"><div class="metric-val">' . $memUsed . ' / ' . $memTotal . ' GB</div>'
       . '<div class="metric-lbl">' . $memPct . '% used &middot; ' . $memFree . ' GB free</div></div>'
       . '<div class="meter ' . meter_class($memPct) . '"><div class="meter-fill" style="width:' . $memPct . '%"></div></div></div>';
    echo '<div class="card"><h3>Disk (' . e(substr(OZI_INSTALL, 0, 2)) . ')</h3><div class="metric">'
       . '<div class="metric-val">' . round($disk['free'] / 1073741824, 1) . ' / ' . round($disk['total'] / 1073741824, 1) . ' GB</div>'
       . '<div class="metric-lbl">' . $diskPct . '% used &middot; ' . round($disk['free'] / 1073741824, 1) . ' GB free</div></div>'
       . '<div class="meter ' . meter_class($diskPct) . '"><div class="meter-fill" style="width:' . $diskPct . '%"></div></div></div>';
    echo '</div>';

    echo '<div class="card"><h3>Installed software versions</h3>';
    echo '<div class="card-scroll"><table class="grid"><thead>'
       . '<tr><th>Component</th><th>Version</th><th>Location</th></tr></thead><tbody>';
    $stack = array(
        array('Apache HTTP Server', $ver['apache'], OZI_INSTALL . '\apache24'),
        array('PHP', $ver['php'], OZI_INSTALL . '\php54'),
        array('MariaDB', $ver['mariadb'], OZI_INSTALL . '\mariadb'),
        array('phpMyAdmin', $ver['phpmyadmin'], OZI_INSTALL . '\phpmyadmin'),
    );
    foreach ($stack as $row) {
        echo '<tr><td>' . e($row[0]) . '</td><td><b>' . e($row[1]) . '</b></td><td class="sub">' . e($row[2]) . '</td></tr>';
    }
    echo '</tbody></table></div></div>';

    page_footer();
}

function sys_mem_pct($mem)
{
    return ($mem['total_kb'] > 0)
        ? round(100 * ($mem['total_kb'] - $mem['free_kb']) / $mem['total_kb'])
        : 0;
}
