<?php
/**
 * Processes page: top processes by memory footprint.
 */

function page_processes()
{
    page_header('Processes', 'processes');

    echo '<div class="card"><h3>Top processes by memory usage</h3>';
    echo '<p class="sub">Snapshot of the largest running processes. Values are approximate '
       . 'and change rapidly on a busy server. Use refresh for an updated view.</p>';
    $rows = top_processes(20);
    if ($rows) {
        $total = 0;
        foreach ($rows as $r) { $total += $r['mb']; }
        echo '<table class="grid"><thead><tr><th>PID</th><th>Process</th><th>Memory (MB)</th><th>CPU (s)</th></tr></thead><tbody>';
        foreach ($rows as $r) {
            $pct = $total > 0 ? round(100 * $r['mb'] / $total) : 0;
            echo '<tr><td>' . e($r['id']) . '</td><td>' . e($r['name']) . '</td>'
               . '<td><div class="pbar"><div class="pfill" style="width:' . $pct . '%"></div></div> '
               . e($r['mb']) . ' MB (' . $pct . '%)</td>'
               . '<td>' . e($r['cpu']) . '</td></tr>';
        }
        echo '</tbody></table>';
        echo '<p class="sub">Total among top ' . count($rows) . ': ' . round($total, 1) . ' MB. '
           . 'Top memory per process total: click refresh to resample.</p>';
    } else {
        echo '<p class="sub">Could not enumerate processes.</p>';
    }
    echo '</div>';

    echo '<div class="card"><h3>Refresh</h3><form method="post"><input type="hidden" name="refresh" value="1" />'
       . csrf_field() . '<button class="btn primary" onclick="location.reload(); return false;">Refresh snapshot</button></form></div>';

    page_footer();
}