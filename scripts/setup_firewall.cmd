@echo off
rem ==========================================================
rem  setup_firewall.cmd - Module 7 (Firewall)
rem  Opens inbound TCP ports for Apache (HTTP) and MariaDB.
rem  Ports are read from config\server.ini.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=setup_firewall.log"
call "%~dp0common.cmd" log "=== setup_firewall.cmd start ==="

net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )

set "HTTP_RULE=OZI-RIS HTTP %APACHE_PORT%"
set "DB_RULE=OZI-RIS MariaDB %MYSQL_PORT%"

netsh advfirewall firewall add rule name="%HTTP_RULE%" dir=in action=allow protocol=TCP localport=%APACHE_PORT% profile=domain,private
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Failed to create firewall rule %HTTP_RULE%"
    echo [ERROR] Failed to create firewall rule "%HTTP_RULE%".
    exit /b 1
)

netsh advfirewall firewall add rule name="%DB_RULE%" dir=in action=allow protocol=TCP localport=%MYSQL_PORT% profile=domain,private
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Failed to create firewall rule %DB_RULE%"
    echo [ERROR] Failed to create firewall rule "%DB_RULE%".
    exit /b 1
)

call "%~dp0common.cmd" log "[OK] Firewall rules created"
echo [OK] Firewall rules created for TCP %APACHE_PORT% and TCP %MYSQL_PORT%.
exit /b 0
