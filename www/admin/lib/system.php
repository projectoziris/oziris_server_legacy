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
    $res = @mysqli_query($conn, "SELECT COUNT(*) AS n, IFNULL(SUM(data_length+index_length),0) AS s FROM information_schema.TABLES WHERE table_schema='" . mysqli_real_escape_string($conn, OZI_DB_NAME) . "'");
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

function meter_class($pct)
{
    if ($pct >= 90) { return 'bad'; }
    if ($pct >= 75) { return 'warn'; }
    return 'good';
}

function sys_os()
{
    $out = array();
    run_shell('wmic OS get Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime /value', $out);
    $info = array('caption' => '', 'version' => '', 'build' => '', 'arch' => '', 'boot' => '');
    foreach ($out as $line) {
        if (preg_match('/Caption=(.+)/', $line, $m)) { $info['caption'] = trim($m[1]); }
        if (preg_match('/Version=(.+)/', $line, $m)) { $info['version'] = trim($m[1]); }
        if (preg_match('/BuildNumber=(.+)/', $line, $m)) { $info['build'] = trim($m[1]); }
        if (preg_match('/OSArchitecture=(.+)/', $line, $m)) { $info['arch'] = trim($m[1]); }
        if (preg_match('/LastBootUpTime=(.+)/', $line, $m)) { $info['boot'] = trim($m[1]); }
    }
    return $info;
}

function sys_hostname()
{
    $out = array();
    run_shell('hostname', $out);
    return isset($out[0]) ? trim($out[0]) : '';
}

function sys_hardware()
{
    $out = array();
    run_shell('wmic computersystem get Manufacturer,Model,SystemType /value', $out);
    $info = array('manufacturer' => '', 'model' => '', 'type' => '');
    foreach ($out as $line) {
        if (preg_match('/Manufacturer=(.+)/', $line, $m)) { $info['manufacturer'] = trim($m[1]); }
        if (preg_match('/Model=(.+)/', $line, $m)) { $info['model'] = trim($m[1]); }
        if (preg_match('/SystemType=(.+)/', $line, $m)) { $info['type'] = trim($m[1]); }
    }
    return $info;
}

function sys_cpu_detail()
{
    $out = array();
    run_shell('wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /value', $out);
    $info = array('name' => '', 'cores' => '', 'threads' => '', 'speed' => '');
    foreach ($out as $line) {
        if (preg_match('/Name=(.+)/', $line, $m)) { $info['name'] = trim($m[1]); }
        if (preg_match('/NumberOfCores=(.+)/', $line, $m)) { $info['cores'] = trim($m[1]); }
        if (preg_match('/NumberOfLogicalProcessors=(.+)/', $line, $m)) { $info['threads'] = trim($m[1]); }
        if (preg_match('/MaxClockSpeed=(.+)/', $line, $m)) { $info['speed'] = trim($m[1]); }
    }
    return $info;
}

function sys_uptime()
{
    $os = sys_os();
    if (empty($os['boot'])) { return ''; }
    // format: 20260803011638.814253+480
    if (preg_match('/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/', $os['boot'], $m)) {
        $boot = mktime((int)$m[4], (int)$m[5], (int)$m[6], (int)$m[2], (int)$m[3], (int)$m[1]);
        $diff = time() - $boot;
        if ($diff < 0) { $diff = 0; }
        $d = floor($diff / 86400);
        $h = floor(($diff % 86400) / 3600);
        $i = floor(($diff % 3600) / 60);
        $s = $diff % 60;
        return sprintf('%dd %02dh %02dm %02ds', $d, $h, $i, $s);
    }
    return '';
}

function sys_boot_time()
{
    $os = sys_os();
    if (empty($os['boot']) || !preg_match('/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/', $os['boot'], $m)) {
        return '';
    }
    return date('Y-m-d H:i:s', mktime((int)$m[4], (int)$m[5], (int)$m[6], (int)$m[2], (int)$m[3], (int)$m[1]));
}

function sys_versions()
{
    $v = array();
    // Apache: prefer the running server's version from the error log banner,
    // since spawning httpd.exe -v while the service is running can hang.
    $apache = 'n/a';
    $errlog = OZI_INSTALL . '\apache24\logs\error.log';
    if (file_exists($errlog)) {
        foreach (array_slice(array_reverse((array)file($errlog)), 0, 30) as $l) {
            if (preg_match('#Apache/([0-9.]+)#', $l, $m)) { $apache = 'Apache ' . $m[1]; break; }
        }
    }
    if ($apache === 'n/a') {
        $out = array();
        run_shell('"' . OZI_INSTALL . '\apache24\bin\httpd.exe" -v', $out);
        $httpd = implode(' ', $out);
        if (preg_match('/Apache\/([0-9.]+)/', $httpd, $m)) { $apache = 'Apache ' . $m[1]; }
    }
    $v['apache'] = $apache;
    // PHP
    $v['php'] = 'PHP ' . PHP_VERSION;
    // MariaDB
    $out = array();
    run_shell('"' . OZI_INSTALL . '\mariadb\bin\mysql.exe" --version', $out);
    $mysql = implode(' ', $out);
    $v['mariadb'] = preg_match('/(Distrib\s+[0-9.]+-MariaDB)/', $mysql, $m6) ? $m6[1] : 'n/a';
    // phpMyAdmin
    $readme = OZI_INSTALL . '\phpmyadmin\README';
    $pma = 'n/a';
    if (file_exists($readme)) {
        $lines = file($readme);
        foreach ((array)$lines as $l) {
            if (stripos($l, 'Version') !== false && preg_match('/([0-9.]+)/', $l, $m)) { $pma = 'phpMyAdmin ' . trim($m[1]); break; }
        }
    }
    $v['phpmyadmin'] = $pma;
    return $v;
}

function net_interfaces()
{
    $out = array();
    run_shell('ipconfig /all', $out);
    $ifaces = array();
    $cur = null;
    foreach ($out as $line) {
        $line = rtrim($line);
        if ($line === '' || trim($line) === 'Windows IP Configuration') { continue; }
        $t = trim($line);
        // Adapter header: a non-indented line not starting with a label
        if (strpos($line, '   ') !== 0 && $t !== '') {
            if ($cur !== null) { $ifaces[] = $cur; }
            $cur = array('name' => $t, 'desc' => '', 'mac' => '', 'dhcp' => '', 'ip' => '', 'mask' => '', 'gw' => '', 'dns' => '', 'state' => '');
            continue;
        }
        if ($cur === null) { continue; }
        if (preg_match('/Description[^:]*:\s*(.+)/', $line, $m)) { $cur['desc'] = trim($m[1]); }
        else if (preg_match('/Physical Address[^:]*:\s*(.+)/', $line, $m)) { $cur['mac'] = trim($m[1]); }
        else if (preg_match('/DHCP Enabled[^:]*:\s*(.+)/', $line, $m)) { $cur['dhcp'] = trim($m[1]); }
        else if (preg_match('/IPv4 Address[^:]*:\s*([0-9.]+)/', $line, $m)) { $cur['ip'] = $m[1]; }
        else if (preg_match('/Subnet Mask[^:]*:\s*([0-9.]+)/', $line, $m)) { $cur['mask'] = $m[1]; }
        else if (preg_match('/Default Gateway[^:]*:\s*([0-9.]+)/', $line, $m)) { $cur['gw'] = $m[1]; }
        else if (preg_match('/DNS Servers[^:]*:\s*([0-9.]+)/', $line, $m)) { $cur['dns'] = $m[1]; }
        else if (preg_match('/Media State[^:]*:\s*(.+)/', $line, $m)) { $cur['state'] = trim($m[1]); }
    }
    if ($cur !== null) { $ifaces[] = $cur; }
    return $ifaces;
}

function net_listening()
{
    $out = array();
    run_shell('netstat -ano -p tcp', $out);
    $pids = array();
    $ports = array();
    foreach ($out as $line) {
        if (preg_match('/TCP\s+(\S+):(\d+)\s+\S+:0\s+LISTENING\s+(\d+)/', $line, $m)) {
            $ports[] = array('addr' => $m[1], 'port' => (int)$m[2], 'pid' => (int)$m[3]);
        }
    }
    return array('ports' => $ports, 'pids' => net_pid_map(array_column_unique(array_map(function ($p) { return $p['pid']; }, $ports))));
}

function net_established()
{
    $out = array();
    run_shell('netstat -ano -p tcp', $out);
    $conns = array();
    foreach ($out as $line) {
        if (preg_match('/TCP\s+(\S+):(\d+)\s+(\S+):(\d+)\s+ESTABLISHED\s+(\d+)/', $line, $m)) {
            $conns[] = array('local' => $m[1] . ':' . $m[2], 'remote' => $m[3] . ':' . $m[4], 'pid' => (int)$m[5]);
        }
    }
    return array('conns' => $conns, 'pids' => net_pid_map(array_column_unique(array_map(function ($c) { return $c['pid']; }, $conns))));
}

function array_column_unique($items) { return array_values(array_unique($items)); }

function net_pid_map($pids)
{
    $map = array();
    if (!$pids) { return $map; }
    $out = array();
    run_shell('tasklist /fo csv /nh', $out);
    foreach ($out as $line) {
        if (preg_match('/^"([^"]*)"\s*,"(\d+)"\s*,/', $line, $m)) {
            $map[(int)$m[2]] = $m[1];
        }
    }
    return $map;
}

function firewall_summary()
{
    $out = array();
    run_shell('netsh advfirewall show allprofiles', $out);
    $profiles = array();
    $cur = '';
    foreach ($out as $line) {
        $t = trim($line);
        if (preg_match('/^(Private|Public|Domain) Profile Settings/', $t, $m)) { $cur = $m[1]; $profiles[$cur] = array('state' => '', 'in' => '', 'out' => ''); }
        else if (preg_match('/^State\s+(ON|OFF)/i', $t, $m) && $cur !== '') { $profiles[$cur]['state'] = strtolower($m[1]); }
        else if (preg_match('/^Firewall Policy\s+(.+)/i', $t, $m) && $cur !== '') {
            foreach (explode(',', strtoupper(trim($m[1]))) as $part) {
                if (strpos($part, 'INBOUND') !== false) { $profiles[$cur]['in'] = (strpos($part, 'ALLOW') !== false) ? 'Allow' : 'Block'; }
                if (strpos($part, 'OUTBOUND') !== false) { $profiles[$cur]['out'] = (strpos($part, 'ALLOW') !== false) ? 'Allow' : 'Block'; }
            }
        }
    }
    return $profiles;
}

function top_processes($limit = 12)
{
    $out = array();
    run_shell('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First ' . (int)$limit . ' Id,ProcessName,@{n=\'MB\';e={[math]::Round($_.WorkingSet64/1MB,1)}},@{n=\'CPU\';e={[math]::Round($_.CPU,1)}} | ConvertTo-Csv -NoTypeInformation"', $out);
    $rows = array();
    $started = false;
    foreach ($out as $line) {
        $line = trim($line);
        if (!$started) { if ($line === '"Id","ProcessName","MB","CPU"') { $started = true; } continue; }
        if ($line === '') { continue; }
        $p = str_getcsv($line);
        if (count($p) >= 4) {
            $rows[] = array('id' => (int)$p[0], 'name' => $p[1], 'mb' => (float)$p[2], 'cpu' => (float)$p[3]);
        }
    }
    return $rows;
}
