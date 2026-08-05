<?php
/**
 * Network page: interfaces, listening ports, active connections, firewall.
 */

function page_network()
{
    $ifaces = net_interfaces();
    $fw = firewall_summary();

    page_header('Network', 'network');

    echo '<div class="card"><h3>Firewall status</h3>';
    if ($fw) {
        echo '<div class="card-scroll"><table class="grid"><thead><tr><th>Profile</th><th>State</th><th>Inbound</th><th>Outbound</th></tr></thead><tbody>';
        foreach ($fw as $name => $p) {
            $stateCls = ($p['state'] === 'on') ? 'good' : 'bad';
            $inCls = ($p['in'] === 'Allow') ? 'good' : 'warn';
            $outCls = ($p['out'] === 'Allow') ? 'good' : 'warn';
            $inVal = ($p['in'] === '') ? '&ndash;' : $p['in'];
            $outVal = ($p['out'] === '') ? '&ndash;' : $p['out'];
            echo '<tr><td>' . e($name) . '</td>'
               . '<td><span class="badge ' . $stateCls . '">' . e(strtoupper($p['state'])) . '</span></td>'
               . '<td><span class="badge ' . $inCls . '">' . $inVal . '</span></td>'
               . '<td><span class="badge ' . $outCls . '">' . $outVal . '</span></td></tr>';
        }
        echo '</tbody></table></div>';
    } else {
        echo '<p class="sub">Firewall status unavailable (netsh requires elevation).</p>';
    }
    echo '</div>';

    echo '<div class="card"><h3>Network interfaces</h3>';
    if ($ifaces) {
        echo '<div class="card-scroll"><table class="grid"><thead><tr><th>Adapter</th><th>IP address</th><th>Subnet</th><th>Gateway</th><th>MAC</th><th>DHCP</th></tr></thead><tbody>';
        foreach ($ifaces as $i) {
            echo '<tr><td>' . e($i['name']) . '<br /><span class="sub">' . e($i['desc']) . '</span></td>'
               . '<td>' . e($i['ip']) . '</td>'
               . '<td>' . e($i['mask']) . '</td>'
               . '<td>' . e($i['gw']) . '</td>'
               . '<td class="mono">' . e($i['mac']) . '</td>'
               . '<td>' . e($i['dhcp']) . '</td></tr>';
        }
        echo '</tbody></table></div>';
    } else {
        echo '<p class="sub">No interface data.</p>';
    }
    echo '</div>';

    $listening = net_listening();
    echo '<div class="card"><h3>Listening ports (TCP)</h3>';
    if (!empty($listening['ports'])) {
        echo '<div class="card-scroll"><table class="grid"><thead><tr><th>Address</th><th>Port</th><th>Service</th><th>PID</th></tr></thead><tbody>';
        usort($listening['ports'], function ($a, $b) { return $a['port'] - $b['port']; });
        foreach ($listening['ports'] as $p) {
            $proc = isset($listening['pids'][$p['pid']]) ? $listening['pids'][$p['pid']] : '?';
            echo '<tr><td>' . e($p['addr']) . '</td><td class="mono">' . e($p['port']) . '</td><td>' . e($proc) . '</td><td>' . e($p['pid']) . '</td></tr>';
        }
        echo '</tbody></table></div>';
    } else {
        echo '<p class="sub">No listening TCP ports detected.</p>';
    }
    echo '</div>';

    $est = net_established();
    echo '<div class="card"><h3>Active TCP connections</h3>';
    if (!empty($est['conns'])) {
        echo '<div class="card-scroll"><table class="grid"><thead><tr><th>Local</th><th>Remote</th><th>Process</th><th>PID</th></tr></thead><tbody>';
        usort($est['conns'], function ($a, $b) { return strcmp($a['remote'], $b['remote']); });
        foreach ($est['conns'] as $c) {
            $proc = isset($est['pids'][$c['pid']]) ? $est['pids'][$c['pid']] : '?';
            echo '<tr><td class="mono">' . e($c['local']) . '</td><td class="mono">' . e($c['remote']) . '</td><td>' . e($proc) . '</td><td>' . e($c['pid']) . '</td></tr>';
        }
        echo '</tbody></table></div>';
    } else {
        echo '<p class="sub">No active connections.</p>';
    }
    echo '</div>';

    page_footer();
}
