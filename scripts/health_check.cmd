@echo off
rem ==========================================================
rem  health_check.cmd - Module 9 (Health Check)
rem  Verifies Apache, PHP, MariaDB, ports, disk, RAM, CPU and
rem  Windows services. Exit code: 0=HEALTHY, 1=WARNING, 2=CRITICAL.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=health_check.log"
call "%~dp0common.cmd"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Health-Check.ps1"
set "RC=!errorlevel!"

echo.
if "!RC!"=="0" echo HEALTH STATUS : HEALTHY
if "!RC!"=="1" echo HEALTH STATUS : WARNING
if "!RC!"=="2" echo HEALTH STATUS : CRITICAL
call "%~dp0common.cmd" log "health check completed with status !RC!"
exit /b !RC!
