# OZI-RIS Server Pack

A professional Windows server package for legacy PHP applications (primarily OZI-RIS),
built as a modular replacement for XAMPP.

- Apache 2.4
- PHP 5.4.45
- MariaDB 10.1
- phpMyAdmin 4.4
- Windows 10 Pro (intranet only, no Internet exposure)

## Layout

```
apache/          Apache 2.4 binary distribution (place zip contents here)
php54/           PHP 5.4.45 binary distribution
mariadb/         MariaDB 10.1 binary distribution
phpmyadmin/      phpMyAdmin 4.4 distribution
installer/       One-click installer / uninstaller
scripts/         Module scripts (install / remove / manage)
config/          server.ini + service configuration templates
logs/            Runtime logs
backup/          Backups
www/             Web root (OZI-RIS application)
docs/            Documentation
tests/           Module test scripts
```

## Quick start

1. Download the required binary distributions (see `docs/INSTALLATION.md` for URLs)
   and extract them into `apache\`, `php54\`, `mariadb\`, `phpmyadmin\`.
2. Review `config\server.ini` (ports, passwords, timezone, paths).
3. Run as Administrator: `installer\install.cmd`
4. Manage the server: `scripts\server_manager.cmd`

## Exit codes

Every script returns a standard exit code:

| Code | Meaning |
|------|---------|
| 0    | Success |
| 1    | General error |
| 2    | Missing dependency (binary not found) |
| 3    | Wrong state (already installed / not installed) |
| 4    | Validation / configuration error |

## Modules

| # | Module            | Scripts |
|---|-------------------|---------|
| 1 | Skeleton          | `config\server.ini`, `scripts\common.cmd` |
| 2 | Apache            | `scripts\install_apache.cmd`, `scripts\remove_apache.cmd` |
| 3 | PHP               | `scripts\install_php.cmd`, `scripts\configure_php.cmd` |
| 4 | MariaDB           | `scripts\install_mariadb.cmd`, `scripts\remove_mariadb.cmd` |
| 5 | phpMyAdmin        | `scripts\deploy_phpmyadmin.cmd` |
| 6 | Windows Services  | `scripts\install_services.cmd`, `start_*.cmd`, `stop_*.cmd`, `restart_*.cmd`, `status_*.cmd` |
| 7 | Firewall          | `scripts\setup_firewall.cmd`, `scripts\remove_firewall.cmd`, `scripts\verify_firewall.cmd` |
| 8 | Backup            | `scripts\backup.cmd`, `scripts\restore.cmd` |
| 9 | Health Check      | `scripts\health_check.cmd` |
| 10| Migration         | `scripts\migrate_xampp.cmd` |
| 11| Server Manager   | `scripts\server_manager.cmd` |
| 12| Installer         | `installer\install.cmd`, `installer\uninstall.cmd` |

See `docs\` for installation, configuration, troubleshooting and rollback per module.
