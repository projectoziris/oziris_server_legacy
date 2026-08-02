@echo off
rem ==========================================================
rem  remove_apache.cmd - Module 2 rollback / removal
rem  Stops and deletes the Apache24 service, then removes the
rem  installed Apache directory. Pass -KeepFiles to keep files.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=remove_apache.log"
call "%~dp0common.cmd" log "=== remove_apache.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "APACHE_DEST=!SERVER_INSTALL_PATH!\apache24"

sc query Apache24 >nul 2>&1
if errorlevel 1 (
    echo [INFO] Apache24 service is not installed.
) else (
    echo [INFO] Stopping Apache24 service...
    sc stop Apache24 >nul 2>&1
    timeout /t 3 /nobreak >nul
    echo [INFO] Deleting Apache24 service...
    sc delete Apache24 >nul
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[ERROR] sc delete Apache24 failed"
        echo [ERROR] Failed to delete Apache24 service.
        exit /b 1
    )
)

if /i "%~1"=="-KeepFiles" (
    echo [INFO] Keeping files in "!APACHE_DEST!".
) else (
    if exist "!APACHE_DEST!" (
        echo [INFO] Removing "!APACHE_DEST!"...
        rmdir /s /q "!APACHE_DEST!"
        if errorlevel 1 (
            call "%~dp0common.cmd" log "[ERROR] Failed to remove Apache directory"
            echo [ERROR] Failed to remove "!APACHE_DEST!".
            exit /b 1
        )
    )
)

call "%~dp0common.cmd" log "[OK] Apache removed"
echo [OK] Apache removed.
exit /b 0
