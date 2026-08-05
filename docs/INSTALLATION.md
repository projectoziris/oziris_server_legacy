# Installation

## Prerequisites

- Windows 10 Pro (22H2) x86/x64, intranet only
- Administrator account (UAC elevation required)
- Microsoft Visual C++ 2008 SP1 Redistributable (x86) — required by PHP 5.4 (VC9)
- Microsoft Visual C++ 2015-2022 Redistributable (x64) — required by modern Apache Lounge builds (use the VS17 build)

## Download the binary distributions

Extract each archive so the **contents** (not a nested folder) end up in the matching folder:

| Component | Version | Source | Extract into |
|-----------|---------|--------|--------------|
| Apache | 2.4.x (VC9 x86 or VS17) | https://www.apachelounge.com/download/ | `apache\` |
| PHP | 5.4.45 Thread Safe VC9 x86 | https://windows.php.net/downloads/releases/archives/ (`php-5.4.45-Win32-VC9-x86.zip`) | `php54\` |
| MariaDB | 10.1.48 | https://downloads.mariadb.org/mariadb/10.1.48/ | `mariadb\` |
| phpMyAdmin | 4.4.15.10 | https://www.phpmyadmin.net/downloads/ | `phpmyadmin\` |

Each folder must contain the files directly, for example:

```
apache\Apache24\bin\httpd.exe      (or apache\bin\httpd.exe)
php54\php.exe
php54\php5apache2_4.dll
mariadb\bin\mysqld.exe
mariadb\bin\mysql_install_db.exe
phpmyadmin\index.php
```

> PHP 5.4 must be the **Thread Safe** build — the non-thread-safe zip does not
> contain `php5apache2_4.dll` which the Apache module integration requires.

## Install

1. Review `config\server.ini` (ports, passwords, timezone, backup retention).
2. Right-click `installer\install.cmd` and choose **Run as administrator**.

The installer runs every module in order:

1. Apache (install, register `Apache24` service, start)
2. PHP (install, generate `php.ini`, integrate with Apache)
3. MariaDB (install, initialize data dir, register `MariaDB` service, start, create DB + user)
4. phpMyAdmin (deploy + generate `config.inc.php`)
5. Windows Services (auto-start both services)
6. Admin Panel (deploy to web root; set credentials on first use)
7. Firewall (inbound TCP rules for HTTP and MariaDB ports)
8. Shortcuts (Desktop + Start Menu)

If any step fails, the installer rolls back automatically and logs to `logs\install.log`.

## Verify

- Web site: http://localhost:80/ (shows the module self-check page)
- phpMyAdmin: http://localhost:80/phpmyadmin/
- Admin Panel: http://localhost:80/admin/ (first visit sets the admin credentials)
- `scripts\health_check.cmd` returns `HEALTHY`
- `scripts\status_apache.cmd` / `scripts\status_mariadb.cmd` report `RUNNING`

## Manual (module-by-module) installation

Each module can be installed and removed independently:

```
scripts\install_apache.cmd
scripts\install_php.cmd
scripts\install_mariadb.cmd
scripts\deploy_phpmyadmin.cmd
scripts\deploy_admin.cmd
scripts\install_services.cmd
scripts\setup_firewall.cmd
```

Installation order matters: Apache, PHP, MariaDB, then the rest.
