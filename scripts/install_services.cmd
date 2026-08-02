@echo off
rem ==========================================================
rem  install_services.cmd - Module 6 (Windows Services)
rem  Sets both services to Auto start and starts them.
rem  Registration itself is performed by install_apache.cmd and
rem  install_mariadb.cmd.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=install_services.log"
call "%~dp0common.cmd" log "=== install_services.cmd start ==="

net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )

set "FAILED="
for %%s in (Apache24 MariaDB) do (
    sc query %%s >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Service %%s is not installed. Run install_apache.cmd / install_mariadb.cmd first.
        set "FAILED=!FAILED! %%s"
    ) else (
        sc config %%s start= auto >nul
        sc query %%s | findstr /i "RUNNING" >nul
        if errorlevel 1 (
            echo [INFO] Starting %%s...
            sc start %%s >nul
        )
    )
)
if defined FAILED (
    call "%~dp0common.cmd" log "[ERROR] Missing services:!FAILED!"
    echo [ERROR] Missing services:!FAILED!
    exit /b 1
)

call "%~dp0common.cmd" log "[OK] Services configured to auto-start"
echo [OK] Apache24 and MariaDB are set to auto-start.
exit /b 0
