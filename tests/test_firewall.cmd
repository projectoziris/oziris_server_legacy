@echo off
rem Test: Firewall (rules present, negative, recreate)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_firewall.log"
call "%~dp0..\scripts\common.cmd" log "=== test_firewall.cmd ==="
set "FAILED=0"
set "HTTP_RULE=OZI-RIS HTTP %APACHE_PORT%"
set "DB_RULE=OZI-RIS MariaDB %MYSQL_PORT%"

if not exist "!SERVER_INSTALL_PATH!\apache24" ( echo [SKIP] server not installed - setup_firewall.cmd required & exit /b 2 )

netsh advfirewall firewall show rule name="%HTTP_RULE%" >nul 2>&1
if errorlevel 1 ( echo [FAIL] rule "%HTTP_RULE%" missing & set "FAILED=1" ) else ( echo [PASS] rule "%HTTP_RULE%" present )
netsh advfirewall firewall show rule name="%DB_RULE%" >nul 2>&1
if errorlevel 1 ( echo [FAIL] rule "%DB_RULE%" missing & set "FAILED=1" ) else ( echo [PASS] rule "%DB_RULE%" present )

call "%~dp0..\scripts\setup_firewall.cmd" >nul 2>&1
if errorlevel 1 ( echo [FAIL] re-running setup_firewall failed & set "FAILED=1" ) else ( echo [PASS] setup_firewall idempotent )

call "%~dp0..\scripts\common.cmd" log "test_firewall result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
