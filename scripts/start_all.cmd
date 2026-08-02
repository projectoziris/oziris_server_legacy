@echo off
rem ==========================================================
rem  start_all.cmd - Safety-net startup helper
rem  Starts both OZI-RIS services. Safe to re-run: services
rem  that are already running are left untouched.
rem  Used by the "OZI-RIS Startup Safety Net" scheduled task
rem  (delayed start) in case the auto-start services race the
rem  network/port availability at boot.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=start_all.log"
call "%~dp0common.cmd"

net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )

set "RC=0"
for %%s in (MariaDB Apache24) do (
    sc query %%s >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Service %%s is not installed.
        set "RC=1"
    ) else (
        sc query %%s | findstr /i "RUNNING" >nul
        if not errorlevel 1 (
            echo [INFO] %%s is already running.
        ) else (
            echo [INFO] Starting %%s...
            sc start %%s >nul
            if errorlevel 1 (
                echo [ERROR] Failed to start %%s.
                call "%~dp0common.cmd" log "[ERROR] start_all: sc start %%s failed"
                set "RC=1"
            )
        )
    )
)

call "%~dp0common.cmd" log "start_all completed with exit code !RC!"
exit /b !RC!
