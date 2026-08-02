<?php
/**
 * Backup page: list archives, create new backup, download, restore.
 */

function page_backup()
{
    $result = null;

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!csrf_ok()) {
            $result = array('error', 'Invalid CSRF token. Try again.');
        } else {
            $action = isset($_POST['action']) ? $_POST['action'] : '';
            if ($action === 'create') {
                audit('backup create requested');
                $out = array();
                $rc = run_shell('call "' . OZI_ROOT . '\scripts\backup.cmd"', $out);
                $result = array(
                    $rc === 0 ? 'ok' : 'error',
                    ($rc === 0 ? 'Backup created.' : 'Backup failed. See backup.log for details.'),
                    array_slice(array_filter($out, 'strlen'), -8),
                );
            } elseif ($action === 'restore') {
                $file = isset($_POST['file']) ? basename($_POST['file']) : '';
                if (!preg_match('/^backup_[\d_\-]+\.zip$/', $file)
                    || !file_exists(OZI_BACKUP_DIR . '\\' . $file)) {
                    $result = array('error', 'Invalid backup file.');
                } else {
                    audit('backup restore requested: ' . $file);
                    $out = array();
                    $rc = run_shell('call "' . OZI_ROOT . '\scripts\restore.cmd" "' . OZI_BACKUP_DIR . '\\' . $file . '"', $out);
                    $result = array(
                        $rc === 0 ? 'ok' : 'error',
                        ($rc === 0 ? 'Restore completed.' : 'Restore failed. See restore.log for details.'),
                        array_slice(array_filter($out, 'strlen'), -8),
                    );
                }
            } elseif ($action === 'delete') {
                $file = isset($_POST['file']) ? basename($_POST['file']) : '';
                if (!preg_match('/^backup_[\d_\-]+\.zip$/', $file)
                    || !file_exists(OZI_BACKUP_DIR . '\\' . $file)) {
                    $result = array('error', 'Invalid backup file.');
                } else {
                    @unlink(OZI_BACKUP_DIR . '\\' . $file);
                    audit('backup deleted: ' . $file);
                    $result = array('ok', 'Deleted ' . $file . '.');
                }
            } else {
                $result = array('error', 'Unknown action.');
            }
        }
    }

    page_header('Backup', 'backup');

    if ($result) {
        alert($result[0], $result[1]);
        if (isset($result[2]) && $result[2]) {
            echo '<pre class="cmdout">';
            foreach ($result[2] as $l) { echo e($l) . "\n"; }
            echo '</pre>';
        }
    }

    echo '<div class="card">';
    echo '<form method="post"><input type="hidden" name="action" value="create" />' . csrf_field()
       . '<button class="btn primary" onclick="return confirm(\'Create a new backup now?\');">Create backup now</button></form>';
    echo '<p class="sub">Backups are stored in ' . e(OZI_BACKUP_DIR) . '. Retention: ' . (int)ozi_cfg('backup_retention', '7') . ' days.</p>';
    echo '</div>';

    echo '<div class="card"><h3>Existing backups</h3>';
    $list = backup_list();
    if (!$list) {
        echo '<p class="sub">No backups yet.</p>';
    } else {
        echo '<table class="grid"><thead><tr><th>File</th><th>Size</th><th>Created</th><th></th></tr></thead><tbody>';
        foreach ($list as $b) {
            echo '<tr><td>' . e($b['name']) . '</td>';
            echo '<td>' . e(round($b['size'] / 1048576, 2)) . ' MB</td>';
            echo '<td>' . e(date('Y-m-d H:i:s', $b['mtime'])) . '</td>';
            echo '<td class="actions">';
            echo '<a class="btn" href="download.php?f=' . urlencode($b['name']) . '&csrf=' . urlencode($_SESSION['csrf']) . '">Download</a> ';
            echo '<form method="post" class="inline" onsubmit="return confirm(\'Restore ' . e($b['name']) . '? Existing data will be replaced.\');">'
               . '<input type="hidden" name="action" value="restore" /><input type="hidden" name="file" value="' . e($b['name']) . '" />'
               . csrf_field() . '<button class="btn">Restore</button></form> ';
            echo '<form method="post" class="inline" onsubmit="return confirm(\'Delete ' . e($b['name']) . '?\');">'
               . '<input type="hidden" name="action" value="delete" /><input type="hidden" name="file" value="' . e($b['name']) . '" />'
               . csrf_field() . '<button class="btn danger">Delete</button></form>';
            echo '</td></tr>';
        }
        echo '</tbody></table>';
    }
    echo '</div>';

    page_footer();
}
