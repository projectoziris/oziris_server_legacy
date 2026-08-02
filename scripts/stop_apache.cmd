@echo off
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=stop_apache.log"
call "%~dp0common.cmd"
net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )
sc query Apache24 >nul 2>&1
if errorlevel 1 ( echo [INFO] Apache24 service is not installed. & exit /b 0 )
sc query Apache24 | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [INFO] Apache24 is already stopped. & exit /b 0 )
echo [INFO] Stopping Apache24...
sc stop Apache24 >nul
if errorlevel 1 ( echo [ERROR] Failed to stop Apache24. & call "%~dp0common.cmd" log "[ERROR] sc stop Apache24 failed" & exit /b 1 )
ping -n 4 127.0.0.1 >nul
sc query Apache24 | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo [ERROR] Apache24 is still running. & call "%~dp0common.cmd" log "[ERROR] Apache24 still RUNNING" & exit /b 1 )
call "%~dp0common.cmd" log "[OK] Apache24 stopped"
echo [OK] Apache24 stopped.
exit /b 0
