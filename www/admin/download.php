<?php
/**
 * Download handler for backup archives. Requires auth + CSRF token.
 */
require_once __DIR__ . '\lib\bootstrap.php';
require_once __DIR__ . '\lib\auth.php';
auth_require();

$file = isset($_GET['f']) ? basename($_GET['f']) : '';
$csrf = isset($_GET['csrf']) ? $_GET['csrf'] : '';
if (!preg_match('/^backup_[\d_\-]+\.zip$/', $file)
    || $csrf !== $_SESSION['csrf']
    || !file_exists(OZI_BACKUP_DIR . '\\' . $file)) {
    http_response_code(403);
    exit('Forbidden');
}

$path = OZI_BACKUP_DIR . '\\' . $file;
audit('backup downloaded: ' . $file);
header('Content-Type: application/zip');
header('Content-Length: ' . filesize($path));
header('Content-Disposition: attachment; filename="' . $file . '"');
http_headers();
readfile($path);
exit;
