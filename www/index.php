<?php
/**
 * OZI-RIS Server Pack - default landing page.
 */
$checks = array(
    'PHP Version >= 5.4'    => version_compare(PHP_VERSION, '5.4.0', '>='),
    'mysqli extension'      => extension_loaded('mysqli'),
    'gd extension'          => extension_loaded('gd'),
    'openssl extension'     => extension_loaded('openssl'),
    'curl extension'        => extension_loaded('curl'),
    'mbstring extension'    => extension_loaded('mbstring'),
    'fileinfo extension'    => extension_loaded('fileinfo'),
    'phpMyAdmin exists'     => is_dir(__DIR__ . '/../phpmyadmin'),
);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>OZI-RIS Server Pack</title>
    <style>
        body { font-family: "Segoe UI", Arial, sans-serif; margin: 40px auto; max-width: 720px; color: #333; }
        h1 { border-bottom: 2px solid #2c6faa; padding-bottom: 8px; }
        table { border-collapse: collapse; width: 100%; }
        td, th { border: 1px solid #ccc; padding: 6px 10px; text-align: left; }
        .ok { color: #17812b; font-weight: bold; }
        .bad { color: #b22222; font-weight: bold; }
        code { background: #f4f4f4; padding: 1px 4px; }
    </style>
</head>
<body>
    <h1>OZI-RIS Server Pack</h1>
    <p>Server is running. PHP <?php echo PHP_VERSION; ?> on <?php echo php_uname('s'); ?>.</p>
    <table>
        <tr><th>Check</th><th>Result</th></tr>
        <?php foreach ($checks as $name => $ok) { ?>
        <tr>
            <td><?php echo htmlspecialchars($name); ?></td>
            <td class="<?php echo $ok ? 'ok' : 'bad'; ?>"><?php echo $ok ? 'OK' : 'FAIL'; ?></td>
        </tr>
        <?php } ?>
    </table>
    <p><a href="/phpmyadmin/">Open phpMyAdmin</a></p>
</body>
</html>
