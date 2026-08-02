@echo off
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=stop_mariadb.log"
call "%~dp0common.cmd"
net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )
sc query MariaDB >nul 2>&1
if errorlevel 1 ( echo [INFO] MariaDB service is not installed. & exit /b 0 )
sc query MariaDB | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [INFO] MariaDB is already stopped. & exit /b 0 )
echo [INFO] Stopping MariaDB...
sc stop MariaDB >nul
if errorlevel 1 ( echo [ERROR] Failed to stop MariaDB. & call "%~dp0common.cmd" log "[ERROR] sc stop MariaDB failed" & exit /b 1 )
ping -n 5 127.0.0.1 >nul
sc query MariaDB | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo [ERROR] MariaDB is still running. & call "%~dp0common.cmd" log "[ERROR] MariaDB still RUNNING" & exit /b 1 )
call "%~dp0common.cmd" log "[OK] MariaDB stopped"
echo [OK] MariaDB stopped.
exit /b 0
