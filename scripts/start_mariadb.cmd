@echo off
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=start_mariadb.log"
call "%~dp0common.cmd"
net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )
sc query MariaDB >nul 2>&1
if errorlevel 1 ( echo [ERROR] MariaDB service is not installed. & call "%~dp0common.cmd" log "[ERROR] MariaDB not installed" & exit /b 3 )
sc query MariaDB | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo [INFO] MariaDB is already running. & exit /b 0 )
echo [INFO] Starting MariaDB...
sc start MariaDB >nul
if errorlevel 1 ( echo [ERROR] Failed to start MariaDB. & call "%~dp0common.cmd" log "[ERROR] sc start MariaDB failed" & exit /b 1 )
ping -n 5 127.0.0.1 >nul
sc query MariaDB | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [ERROR] MariaDB did not reach RUNNING state. & call "%~dp0common.cmd" log "[ERROR] MariaDB not RUNNING after start" & exit /b 1 )
call "%~dp0common.cmd" log "[OK] MariaDB started"
echo [OK] MariaDB is running.
exit /b 0
