@echo off
rem ==========================================================
rem  verify_firewall.cmd - Module 7 verification
rem  Confirms both inbound TCP rules exist. Exit 0 = present,
rem  1 = missing.
rem ==========================================================
setlocal EnableDelayedExpansion
call "%~dp0common.cmd"
set "HTTP_RULE=OZI-RIS HTTP %APACHE_PORT%"
set "DB_RULE=OZI-RIS MariaDB %MYSQL_PORT%"

set "RC=0"
netsh advfirewall firewall show rule name="%HTTP_RULE%" >nul 2>&1
if errorlevel 1 ( echo [WARN] Rule "%HTTP_RULE%" missing. & set "RC=1" ) else ( echo [OK]   Rule "%HTTP_RULE%" present. )

netsh advfirewall firewall show rule name="%DB_RULE%" >nul 2>&1
if errorlevel 1 ( echo [WARN] Rule "%DB_RULE%" missing. & set "RC=1" ) else ( echo [OK]   Rule "%DB_RULE%" present. )

exit /b %RC%
