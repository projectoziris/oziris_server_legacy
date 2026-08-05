@echo off
rem ==========================================================
rem  install.cmd - Module 12 (Installer)
rem  One-click installation of the whole OZI-RIS Server Pack.
rem  Runs every module script in order with a progress bar,
rem  logs to logs\install.log and rolls back on failure.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=install.log"
call "%~dp0..\scripts\common.cmd" log "=== installer start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Run this installer as Administrator.
    call "%~dp0..\scripts\common.cmd" log "[ERROR] installer requires administrator"
    exit /b 1
)

echo.
echo  ================================================
echo   OZI-RIS Server Pack - One-click Installer
echo  ================================================
echo   Install path : !SERVER_INSTALL_PATH!
echo   HTTP port    : !APACHE_PORT!
echo   DB port      : !MYSQL_PORT!
echo   Database     : !DB_NAME!
echo  ================================================
echo.

set "SCRIPTS=%~dp0..\scripts"
set "TOTAL=8"

echo [ 1/!TOTAL! ] Installing Apache...
call "!SCRIPTS!\install_apache.cmd"
if errorlevel 3 ( echo [INFO] Apache already installed - continuing. ) else if errorlevel 1 goto :fail

echo [ 2/!TOTAL! ] Installing PHP...
call "!SCRIPTS!\install_php.cmd"
if errorlevel 3 ( echo [INFO] PHP already installed - continuing. ) else if errorlevel 1 goto :fail

echo [ 3/!TOTAL! ] Installing MariaDB...
call "!SCRIPTS!\install_mariadb.cmd"
if errorlevel 3 ( echo [INFO] MariaDB already installed - continuing. ) else if errorlevel 1 goto :fail

echo [ 4/!TOTAL! ] Deploying phpMyAdmin...
call "!SCRIPTS!\deploy_phpmyadmin.cmd"
if errorlevel 3 ( echo [INFO] phpMyAdmin already deployed - continuing. ) else if errorlevel 1 goto :fail

echo [ 5/!TOTAL! ] Configuring Windows Services...
call "!SCRIPTS!\install_services.cmd"
if errorlevel 1 goto :fail

echo [ 6/!TOTAL! ] Deploying Admin Panel...
call "!SCRIPTS!\deploy_admin.cmd"
if errorlevel 3 ( echo [INFO] Admin panel source missing - continuing. ) else if errorlevel 1 goto :fail

echo [ 7/!TOTAL! ] Configuring Firewall...
call "!SCRIPTS!\setup_firewall.cmd"
if errorlevel 1 goto :fail

echo [ 8/!TOTAL! ] Creating shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPTS!\lib\Create-Shortcuts.ps1" -PackRoot "%~dp0.." -Port "!APACHE_PORT!"
if errorlevel 1 goto :fail

echo.
echo  ================================================
echo   Verifying installation...
echo  ================================================

call "!SCRIPTS!\health_check.cmd"
if errorlevel 2 goto :fail

call "!SCRIPTS!\verify_firewall.cmd"
if errorlevel 1 (
    echo [WARN] Firewall rules not fully verified.
)

call "%~dp0..\scripts\common.cmd" log "[OK] Installation completed"
echo.
echo  ================================================
echo   Installation complete.
echo   - Web site      : http://localhost:!APACHE_PORT!/
echo   - phpMyAdmin    : http://localhost:!APACHE_PORT!/phpmyadmin/
echo   - Admin Panel   : http://localhost:!APACHE_PORT!/admin/
echo   - Server Manager: "!SCRIPTS!\server_manager.cmd"
echo  ================================================
echo.
pause
exit /b 0

:fail
call "%~dp0..\scripts\common.cmd" log "[ERROR] Installation failed - rolling back"
echo.
echo [ERROR] Installation failed. Rolling back...
call "%~dp0uninstall.cmd" -Silent
echo [ERROR] Rollback finished. See logs\install.log.
pause
exit /b 1
