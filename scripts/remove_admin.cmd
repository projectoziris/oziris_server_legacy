@echo off
rem ==========================================================
rem  remove_admin.cmd - Admin Panel rollback / removal
rem  Removes the deployed admin panel from the install web root.
rem  Pass -KeepFiles to keep files.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=remove_admin.log"
call "%~dp0common.cmd" log "=== remove_admin.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "ADMIN_DEST=!SERVER_INSTALL_PATH!\www\admin"

if /i "%~1"=="-KeepFiles" (
    echo [INFO] Keeping files in "!ADMIN_DEST!".
) else (
    if exist "!ADMIN_DEST!" (
        echo [INFO] Removing "!ADMIN_DEST!"...
        rmdir /s /q "!ADMIN_DEST!"
        if errorlevel 1 (
            call "%~dp0common.cmd" log "[ERROR] Failed to remove admin panel directory"
            echo [ERROR] Failed to remove "!ADMIN_DEST!".
            exit /b 1
        )
    )
)

call "%~dp0common.cmd" log "[OK] Admin panel removed"
echo [OK] Admin panel removed.
exit /b 0