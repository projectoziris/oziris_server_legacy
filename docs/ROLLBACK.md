# Rollback

Every module ships a removal/rollback path. Run the scripts below as Administrator.

## Module removal scripts

| Module | Remove | What it does |
|--------|--------|--------------|
| 2 Apache | `scripts\remove_apache.cmd` | Stops + deletes `Apache24` service, removes `<install>\apache24` |
| 4 MariaDB | `scripts\remove_mariadb.cmd` | Stops + deletes `MariaDB` service, removes `<install>\mariadb` |
| 7 Firewall | `scripts\remove_firewall.cmd` | Deletes the inbound TCP rules for HTTP / MariaDB ports |

`remove_apache.cmd -KeepFiles` and `remove_mariadb.cmd -KeepFiles` keep the files.
`remove_mariadb.cmd -KeepData` keeps the data directory (so the database survives).

## Full uninstall

`installer\uninstall.cmd` removes, in order:

1. Firewall rules
2. `Apache24` service + files
3. `MariaDB` service + files
4. Desktop / Start Menu shortcuts
5. The `<install>` directory (unless `-KeepFiles`)

```
uninstall.cmd          # interactive
uninstall.cmd -Silent  # non-interactive (used by the installer's rollback)
uninstall.cmd -KeepFiles
```

Logs are written to `logs\uninstall.log`.

## Installer failure rollback

If `installer\install.cmd` fails at any step it automatically runs the uninstaller
to leave the system in a clean state. The failure reason is in `logs\install.log`.

## Recovering a previous good state

1. Restore the database and configuration from a backup created by
   `scripts\backup.cmd`:
   ```
   scripts\restore.cmd                    # most recent backup
   scripts\restore.cmd C:\path\backup_2026-08-02_120000.zip
   ```
2. Backups are verified before anything is touched; a corrupt archive is never applied.

## Idempotency

Module scripts are safe to re-run:

- `install_apache.cmd` / `install_mariadb.cmd` exit with code 3 ("already installed")
  when the service exists; the installer treats this as "continue".
- `configure_php.cmd`, `deploy_phpmyadmin.cmd`, `setup_firewall.cmd` regenerate their
  configuration and are safe to re-run at any time.
