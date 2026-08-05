@echo off
rem ==========================================================
rem  deploy_admin.cmd - Admin Panel deployment
rem  Copies the OZI-RIS web admin panel into the install web
rem  root. Credentials (config\admin.ini) are created on the
rem  panel's first-run setup - no SQL database is required.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=deploy_admin.log"
call "%~dp0common.cmd" log "=== deploy_admin.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "ADMIN_SRC=!SERVER_PACK_ROOT!\www\admin"
set "ADMIN_DEST=!SERVER_INSTALL_PATH!\www\admin"

if not exist "!ADMIN_SRC!\index.php" (
    call "%~dp0common.cmd" log "[ERROR] Admin source index.php not found at !ADMIN_SRC!"
    echo [ERROR] Admin panel source not found at "%ADMIN_SRC%". Skipping deployment.
    exit /b 2
)

echo [INFO] Admin source : !ADMIN_SRC!
echo [INFO] Admin target : !ADMIN_DEST!

if not exist "!SERVER_INSTALL_PATH!" mkdir "!SERVER_INSTALL_PATH!"
if not exist "!SERVER_INSTALL_PATH!\www" mkdir "!SERVER_INSTALL_PATH!\www"

echo [INFO] Copying admin panel...
xcopy /e /i /y "!ADMIN_SRC!\*" "!ADMIN_DEST!\" >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] xcopy of admin panel failed"
    echo [ERROR] Failed to copy the admin panel.
    exit /b 1
)

rem Remove the dev-only admin.ini (if any) so each install sets its
rem own credentials on first use. Config lives in the pack root only.
if exist "!ADMIN_DEST!\config\admin.ini" del "!ADMIN_DEST!\config\admin.ini" >nul 2>&1

call "%~dp0common.cmd" log "[OK] Admin panel deployed"
echo [OK] Admin panel deployed at http://localhost:%APACHE_PORT%/admin/
exit /b 0