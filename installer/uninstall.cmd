@echo off
rem ==========================================================
rem  uninstall.cmd - Module 12 (Uninstaller)
rem  Removes firewall rules, Windows services, shortcuts and
rem  (optionally) the installed directory. Usage:
rem      uninstall.cmd [-Silent] [-KeepFiles]
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=uninstall.log"
call "%~dp0..\scripts\common.cmd" log "=== uninstaller start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Run this uninstaller as Administrator.
    call "%~dp0..\scripts\common.cmd" log "[ERROR] uninstaller requires administrator"
    exit /b 1
)

set "SILENT="
set "KEEPFILES="
for %%a in (%*) do (
    if /i "%%a"=="-Silent" set "SILENT=1"
    if /i "%%a"=="-KeepFiles" set "KEEPFILES=1"
)

if not defined SILENT (
    echo.
    echo  This will remove OZI-RIS Server Pack from this computer.
    echo  Install path: !SERVER_INSTALL_PATH!
    choice /m "Continue?"
    if errorlevel 2 exit /b 0
)

echo [INFO] Removing firewall rules...
call "%~dp0..\scripts\remove_firewall.cmd" >nul 2>&1

echo [INFO] Removing Apache...
call "%~dp0..\scripts\remove_apache.cmd" -KeepFiles >nul 2>&1

echo [INFO] Removing MariaDB...
call "%~dp0..\scripts\remove_mariadb.cmd" -KeepFiles >nul 2>&1

echo [INFO] Removing shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\lib\Create-Shortcuts.ps1" -PackRoot "%~dp0.." -Port "!APACHE_PORT!" -Remove
if errorlevel 1 (
    call "%~dp0..\scripts\common.cmd" log "[WARN] Shortcut removal reported errors"
)

if defined KEEPFILES (
    echo [INFO] Keeping files in "!SERVER_INSTALL_PATH!".
) else (
    if exist "!SERVER_INSTALL_PATH!" (
        echo [INFO] Removing "!SERVER_INSTALL_PATH!"...
        rmdir /s /q "!SERVER_INSTALL_PATH!"
        if errorlevel 1 (
            call "%~dp0..\scripts\common.cmd" log "[WARN] Could not remove install directory"
            echo [WARN] Could not remove "!SERVER_INSTALL_PATH!" ^(files in use?^).
        )
    )
)

call "%~dp0..\scripts\common.cmd" log "[OK] Uninstaller finished"
echo.
echo [OK] Uninstall finished.
if not defined SILENT pause
exit /b 0
