@echo off
rem ==========================================================
rem  remove_firewall.cmd - Module 7 rollback
rem  Removes the inbound TCP rules created by setup_firewall.cmd.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=remove_firewall.log"
call "%~dp0common.cmd" log "=== remove_firewall.cmd start ==="

net session >nul 2>&1
if errorlevel 1 ( echo [ERROR] Run as Administrator. & exit /b 1 )

set "HTTP_RULE=OZI-RIS HTTP %APACHE_PORT%"
set "DB_RULE=OZI-RIS MariaDB %MYSQL_PORT%"

netsh advfirewall firewall delete rule name="%HTTP_RULE%" >nul 2>&1
netsh advfirewall firewall delete rule name="%DB_RULE%" >nul 2>&1

call "%~dp0common.cmd" log "[OK] Firewall rules removed"
echo [OK] Firewall rules removed.
exit /b 0
