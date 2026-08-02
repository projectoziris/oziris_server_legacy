<?php
/**
 * Health page: runs scripts\lib\Health-Check.ps1 and renders the report.
 */

function page_health()
{
    $run = false;
    if (isset($_POST['run'])) { $run = csrf_ok(); }

    page_header('Health Check', 'health');

    if ($run) {
        audit('health check run');
        $out = array();
        $rc = run_shell('powershell -NoProfile -ExecutionPolicy Bypass -File "' . OZI_ROOT . '\scripts\lib\Health-Check.ps1" -Json', $out);
        $json = implode("\n", $out);
        $data = json_decode($json, true);
        if (!is_array($data)) {
            alert('error', 'Health check produced no valid output.');
            echo '<pre class="cmdout">' . e($json) . '</pre>';
        } else {
            $status = isset($data['status']) ? $data['status'] : 'unknown';
            $cls = ($status === 'healthy') ? 'good' : (($status === 'warning') ? 'warn' : 'bad');
            alert($cls, 'Overall status: ' . strtoupper($status));
            echo '<div class="card"><table class="grid"><thead><tr><th>Check</th><th>Status</th><th>Detail</th></tr></thead><tbody>';
            foreach ($data['checks'] as $c) {
                $s = isset($c['Status']) ? $c['Status'] : '?';
                $cls2 = ($s === 'OK') ? 'good' : (($s === 'WARN') ? 'warn' : 'bad');
                echo '<tr><td>' . e($c['Name']) . '</td>'
                   . '<td><span class="badge ' . $cls2 . '">' . e($s) . '</span></td>'
                   . '<td>' . e($c['Detail']) . '</td></tr>';
            }
            echo '</tbody></table></div>';
        }
    } else {
        echo '<div class="card">';
        echo '<form method="post"><input type="hidden" name="run" value="1" />' . csrf_field()
           . '<button class="btn primary">Run health check</button></form>';
        echo '<p class="sub">Verifies services, ports, PHP, database login, disk, memory and CPU.</p>';
        echo '</div>';
    }

    page_footer();
}
