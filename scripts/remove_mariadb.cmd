@echo off
rem ==========================================================
rem  remove_mariadb.cmd - Module 4 rollback / removal
rem  Stops and deletes the MariaDB service, then removes the
rem  installed MariaDB directory. Pass -KeepFiles to keep files.
rem  Use -KeepData to keep the data directory.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=remove_mariadb.log"
call "%~dp0common.cmd" log "=== remove_mariadb.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "MDB_DEST=!SERVER_INSTALL_PATH!\mariadb"

sc query MariaDB >nul 2>&1
if errorlevel 1 (
    echo [INFO] MariaDB service is not installed.
) else (
    echo [INFO] Stopping MariaDB service...
    sc stop MariaDB >nul 2>&1
    timeout /t 4 /nobreak >nul
    echo [INFO] Deleting MariaDB service...
    sc delete MariaDB >nul
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[ERROR] sc delete MariaDB failed"
        echo [ERROR] Failed to delete MariaDB service.
        exit /b 1
    )
)

if /i "%~1"=="-KeepFiles" (
    echo [INFO] Keeping files in "!MDB_DEST!".
) else (
    if /i "%~1"=="-KeepData" (
        echo [INFO] Keeping files in "!MDB_DEST!" ^(data preserved^).
    ) else (
        if exist "!MDB_DEST!" (
            echo [INFO] Removing "!MDB_DEST!"...
            rmdir /s /q "!MDB_DEST!"
            if errorlevel 1 (
                call "%~dp0common.cmd" log "[ERROR] Failed to remove MariaDB directory"
                echo [ERROR] Failed to remove "!MDB_DEST!".
                exit /b 1
            )
        )
    )
)

call "%~dp0common.cmd" log "[OK] MariaDB removed"
echo [OK] MariaDB removed.
exit /b 0
