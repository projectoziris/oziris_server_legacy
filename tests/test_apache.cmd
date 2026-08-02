@echo off
rem Test: Apache (positive / negative / stop-start rollback)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_apache.log"
call "%~dp0..\scripts\common.cmd" log "=== test_apache.cmd ==="
set "FAILED=0"
set "HTTPD=!SERVER_INSTALL_PATH!\apache24\bin\httpd.exe"

if not exist "!HTTPD!" ( echo [SKIP] Apache not installed - install_apache.cmd required & exit /b 2 )

sc query Apache24 >nul 2>&1
if errorlevel 1 ( echo [FAIL] Apache24 service missing & set "FAILED=1" ) else ( echo [PASS] Apache24 service present )

sc query Apache24 | findstr /i "RUNNING" >nul
if errorlevel 1 (
    echo [INFO] Apache24 not running - starting...
    sc start Apache24 >nul
    timeout /t 3 /nobreak >nul
)
sc query Apache24 | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [FAIL] Apache24 not RUNNING & set "FAILED=1" ) else ( echo [PASS] Apache24 RUNNING )

powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:!APACHE_PORT!/' -UseBasicParsing -TimeoutSec 15; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 ( echo [FAIL] HTTP request on port !APACHE_PORT! failed & set "FAILED=1" ) else ( echo [PASS] HTTP 200 on port !APACHE_PORT! )

call "%~dp0..\scripts\install_apache.cmd" >nul 2>&1
if errorlevel 3 ( echo [PASS] duplicate install rejected ^(rc=3^) ) else ( echo [FAIL] duplicate install was not rejected & set "FAILED=1" )

echo [INFO] Stop/start rollback test...
sc stop Apache24 >nul
timeout /t 3 /nobreak >nul
sc query Apache24 | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo [FAIL] Apache24 still running after stop & set "FAILED=1" ) else ( echo [PASS] Apache24 stopped )
sc start Apache24 >nul
timeout /t 3 /nobreak >nul
sc query Apache24 | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [FAIL] Apache24 did not restart & set "FAILED=1" ) else ( echo [PASS] Apache24 restarted )

call "%~dp0..\scripts\common.cmd" log "test_apache result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
