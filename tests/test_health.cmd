@echo off
rem Test: Health check (healthy baseline, negative when service stopped)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_health.log"
call "%~dp0..\scripts\common.cmd" log "=== test_health.cmd ==="
set "FAILED=0"

sc query Apache24 >nul 2>&1
if errorlevel 1 (
    sc query MariaDB >nul 2>&1
    if errorlevel 1 ( echo [SKIP] services not installed - install first & exit /b 2 )
)

call "%~dp0..\scripts\health_check.cmd" >nul 2>&1
set "RC=!errorlevel!"
if "!RC!"=="0" ( echo [PASS] health check returned HEALTHY ) else ( echo [FAIL] health check returned !RC! & set "FAILED=1" )

echo [INFO] Negative test: stop Apache24 and expect CRITICAL...
sc query Apache24 >nul 2>&1
if not errorlevel 1 (
    sc query Apache24 | findstr /i "RUNNING" >nul
    if not errorlevel 1 (
        sc stop Apache24 >nul
        timeout /t 3 /nobreak >nul
        call "%~dp0..\scripts\health_check.cmd" >nul 2>&1
        set "RC=!errorlevel!"
        if "!RC!"=="2" ( echo [PASS] health check returned CRITICAL with Apache stopped ) else ( echo [FAIL] expected CRITICAL but got !RC! & set "FAILED=1" )
        sc start Apache24 >nul
        timeout /t 3 /nobreak >nul
    )
)

call "%~dp0..\scripts\common.cmd" log "test_health result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
