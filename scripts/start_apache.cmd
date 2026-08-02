@echo off
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=start_apache.log"
call "%~dp0common.cmd"
net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )
sc query Apache24 >nul 2>&1
if errorlevel 1 ( echo [ERROR] Apache24 service is not installed. & call "%~dp0common.cmd" log "[ERROR] Apache24 not installed" & exit /b 3 )
sc query Apache24 | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo [INFO] Apache24 is already running. & exit /b 0 )
echo [INFO] Starting Apache24...
sc start Apache24 >nul
if errorlevel 1 ( echo [ERROR] Failed to start Apache24. & call "%~dp0common.cmd" log "[ERROR] sc start Apache24 failed" & exit /b 1 )
ping -n 4 127.0.0.1 >nul
sc query Apache24 | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [ERROR] Apache24 did not reach RUNNING state. & call "%~dp0common.cmd" log "[ERROR] Apache24 not RUNNING after start" & exit /b 1 )
call "%~dp0common.cmd" log "[OK] Apache24 started"
echo [OK] Apache24 is running.
exit /b 0
