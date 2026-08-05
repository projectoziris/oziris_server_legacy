# Testing

Every module requires positive, negative, rollback and regression tests.
The scripts in `tests\` cover these. Run each `tests\test_*.cmd` from an
**administrator** console after the relevant module is installed.

## Test harness

Each test script:

- runs the module action and asserts the expected result / exit code
- runs a negative case (e.g., second install, missing binary)
- runs a rollback and verifies cleanup
- logs everything to `logs\` and returns a non-zero exit code on failure

## Test matrix

| Test script | Positive | Negative | Rollback |
|-------------|----------|----------|----------|
| `test_config.cmd` | `common.cmd` parses `server.ini` | missing/malformed ini | restored ini |
| `test_apache.cmd` | service installed + HTTP 200 | duplicate install (rc=3) | `remove_apache.cmd` |
| `test_php.cmd` | `php -m` contains required extensions | missing binary (rc=2) | regenerate config |
| `test_mariadb.cmd` | service running + DB query | duplicate install (rc=3) | `remove_mariadb.cmd` |
| `test_phpmyadmin.cmd` | config.inc.php valid PHP | missing distribution (rc=2) | re-deploy |
| `test_admin.cmd` | files deployed + valid PHP | missing source (rc=2) | re-deploy |
| `test_firewall.cmd` | rules present | rules removed | re-create |
| `test_backup.cmd` | archive created + verified | db down (rc=1) | delete archive |
| `test_restore.cmd` | database restored | corrupt archive refused | no-op on failure |
| `test_health.cmd` | HEALTHY (rc=0) | stopped services → CRITICAL | restart |

## Running the full suite

```
tests\run_all.cmd
```

Exits 0 when every test passes, 1 otherwise. Each module is also independently
verifiable via its install script and `health_check.cmd`.

## Regression

After any configuration or template change, run `tests\run_all.cmd` plus
`scripts\health_check.cmd` to confirm a healthy baseline (HEALTHY, rc=0).
