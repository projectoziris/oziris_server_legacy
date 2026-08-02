<?php
/**
 * OZI-RIS Server Pack - Admin Panel system helpers.
 * Service control, resource stats and database info.
 * Apache runs as LocalSystem, so PHP exec() can manage services.
 */

function ozi_services()
{
    return array('Apache24', 'MariaDB');
}

function svc_status($name)
{
    $out = array();
    run_shell('sc query "' . $name . '"', $out);
    $state = 'unknown';
    foreach ($out as $line) {
        if (stripos($line, 'STATE') !== false) {
            if (preg_match('/:\s*(\d+)\s+([A-Z_]+)/i', $line, $m)) {
                $state = strtolower(trim($m[2]));
            }
        }
    }
    return $state;
}

function svc_action($name, $action)
{
    $actions = array('start', 'stop', 'restart');
    if (!in_array($name, ozi_services(), true) || !in_array($action, $actions, true)) {
        return array(1, array('ERROR: invalid request'));
    }
    $out = array();
    if ($action === 'restart') {
        run_shell('net stop "' . $name . '"', $out);
        $lines = $out;
        run_shell('net start "' . $name . '"', $out2);
        $lines = array_merge($lines, $out2);
        return array(0, $lines);
    }
    $rc = run_shell('net ' . $action . ' "' . $name . '"', $out);
    return array($rc, $out);
}

function is_listening($port)
{
    $out = array();
    run_shell('netstat -ano -p tcp', $out);
    foreach ($out as $line) {
        if (preg_match('/\bTCP\b.*:(' . (int)$port . ')\s+.*LISTENING/i', $line)) {
            return true;
        }
    }
    return false;
}

function sys_memory()
{
    $out = array();
    run_shell('wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /value', $out);
    $free = 0; $total = 0;
    foreach ($out as $line) {
        if (preg_match('/FreePhysicalMemory=(\d+)/', $line, $m)) { $free = (int)$m[1]; }
        if (preg_match('/TotalVisibleMemorySize=(\d+)/', $line, $m)) { $total = (int)$m[1]; }
    }
    return array('free_kb' => $free, 'total_kb' => $total);
}

function sys_cpu()
{
    $out = array();
    run_shell('wmic cpu get loadpercentage /value', $out);
    foreach ($out as $line) {
        if (preg_match('/LoadPercentage=(\d+)/', $line, $m)) { return (int)$m[1]; }
    }
    return 0;
}

function sys_disk()
{
    $drive = substr(OZI_INSTALL, 0, 2);
    $out = array();
    run_shell('wmic logicaldisk where DeviceID="' . $drive . '" get FreeSpace,Size /value', $out);
    $free = 0; $total = 0;
    foreach ($out as $line) {
        if (preg_match('/FreeSpace=(\d+)/', $line, $m)) { $free = (float)$m[1]; }
        if (preg_match('/Size=(\d+)/', $line, $m) && (float)$m[1] > 0) { $total = (float)$m[1]; }
    }
    $pct = $total > 0 ? round(100 * $free / $total) : 0;
    return array('free' => $free, 'total' => $total, 'free_pct' => $pct);
}

function db_info()
{
    $info = array('ok' => false, 'size_mb' => 0, 'tables' => 0, 'error' => '');
    if (!function_exists('mysqli_connect')) { $info['error'] = 'mysqli missing'; return $info; }
    $conn = @mysqli_connect('127.0.0.1', OZI_DB_USER, OZI_DB_PASS, OZI_DB_NAME, (int)OZI_MYSQL_PORT);
    if (!$conn) { $info['error'] = mysqli_connect_error(); return $info; }
    $res = @mysqli_query($conn, "SELECT COUNT(*) AS n, IFNULL(SUM(data_length+index_length),0) AS s FROM information_schema.TABLES WHERE table_schema='my_db'");
    if ($res && $row = mysqli_fetch_assoc($res)) {
        $info['ok'] = true;
        $info['tables'] = (int)$row['n'];
        $info['size_mb'] = round((float)$row['s'] / 1048576, 1);
    }
    mysqli_close($conn);
    return $info;
}

function backup_list()
{
    $items = array();
    if (!is_dir(OZI_BACKUP_DIR)) { return $items; }
    foreach (glob(OZI_BACKUP_DIR . '\backup_*.zip') ?: array() as $f) {
        $items[] = array(
            'name' => basename($f),
            'size' => filesize($f),
            'mtime' => filemtime($f),
        );
    }
    usort($items, function ($a, $b) { return strcmp($b['name'], $a['name']); });
    return $items;
}
