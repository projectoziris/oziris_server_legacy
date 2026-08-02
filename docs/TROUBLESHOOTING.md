# Troubleshooting

## Installer fails at step 1 (Apache)

- Check `logs\install_apache.log`.
- Port 80 in use? Run `netstat -ano | findstr :80` and stop the conflicting service,
  or change `apache_port` in `config\server.ini`.
- Apache binary not found: the archive was not extracted correctly into `apache\`
  (see `docs\INSTALLATION.md` for the required layout).

## `httpd.exe` starts then stops immediately

- Review `<install>\apache24\logs\error.log`.
- `Cannot load php5apache2_4.dll` — you used the **non-thread-safe** PHP build, or the
  VC9 runtime is missing. Re-download the Thread Safe VC9 x86 build and install the
  Microsoft Visual C++ 2008 SP1 redistributable.
- `Syntax error` in `conf\vhost.conf` after a migration — the imported VirtualHost
  blocks are invalid. Remove the `# --- Imported from XAMPP ---` section and re-test.

## PHP files download instead of executing

- The `conf\extra\php.conf` file is missing or empty. Run `scripts\configure_php.cmd`
  to regenerate it, then restart Apache.

## MariaDB service fails to start

- Check `<install>\mariadb\logs\mysql-error.log`.
- Data directory missing/corrupt: run `scripts\remove_mariadb.cmd`, delete
  `<install>\mariadb\data`, then re-run `scripts\install_mariadb.cmd`.
- Port 3306 already in use (e.g., another MySQL/XAMPP): change `mysql_port`.

## phpMyAdmin shows a blank page or login fails

- Confirm the MariaDB service is running and the DB user/password in `server.ini`
  are correct. Re-run `scripts\deploy_phpmyadmin.cmd`.
- Confirm the PHP `mysqli` extension is loaded (see `<install>\php54\logs\php-error.log`).

## `mysqli` extension not loading (php.exe in CLI)

- Confirm `php.ini` has `extension_dir = "<install>\php54\ext"` and the
  `extension=php_mysqli.dll` line is un-commented. Run `scripts\configure_php.cmd`
  to regenerate.

## php.exe does not run at all

- PHP 5.4 (VC9) requires the **Microsoft Visual C++ 2008 SP1 Redistributable (x86)**.

## Backup fails ("mysqldump failed")

- Is the MariaDB service running? Start it and re-run `scripts\backup.cmd`.
- Wrong credentials in `server.ini`.

## Health check returns CRITICAL

- Run `scripts\health_check.cmd` and read the per-check lines. It reports exactly
  which service, port, or resource is failing.
- `Invoke-WebRequest` errors usually mean Apache is down or PHP integration is broken.

## Getting logs

- Module logs: `logs\<module>.log` in the Server Pack root.
- Server logs: `<install>\apache24\logs\`, `<install>\php54\logs\`,
  `<install>\mariadb\logs\`.
