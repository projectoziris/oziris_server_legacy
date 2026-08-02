@echo off
setlocal EnableDelayedExpansion
call "%~dp0common.cmd"
sc query MariaDB >nul 2>&1
if errorlevel 1 ( echo MariaDB    : NOT INSTALLED & exit /b 3 )
sc query MariaDB | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo MariaDB    : RUNNING & exit /b 0 )
echo MariaDB    : STOPPED
exit /b 1
