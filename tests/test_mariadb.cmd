@echo off
rem Test: MariaDB (service, connectivity, negative, stop-start rollback)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_mariadb.log"
call "%~dp0..\scripts\common.cmd" log "=== test_mariadb.cmd ==="
set "FAILED=0"
set "MYSQL=!SERVER_INSTALL_PATH!\mariadb\bin\mysql.exe"

if not exist "!MYSQL!" ( echo [SKIP] MariaDB not installed - install_mariadb.cmd required & exit /b 2 )

sc query MariaDB >nul 2>&1
if errorlevel 1 ( echo [FAIL] MariaDB service missing & set "FAILED=1" ) else ( echo [PASS] MariaDB service present )

sc query MariaDB | findstr /i "RUNNING" >nul
if errorlevel 1 (
    echo [INFO] MariaDB not running - starting...
    sc start MariaDB >nul
    timeout /t 5 /nobreak >nul
)
sc query MariaDB | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [FAIL] MariaDB not RUNNING & set "FAILED=1" ) else ( echo [PASS] MariaDB RUNNING )

"!MYSQL!" -u !DB_USER! -p!DB_PASS! -h 127.0.0.1 -P !MYSQL_PORT! -e "USE !DB_NAME!; SELECT 1;" >nul 2>&1
if errorlevel 1 ( echo [FAIL] database !DB_NAME! / user !DB_USER! connection failed & set "FAILED=1" ) else ( echo [PASS] database !DB_NAME! reachable with user !DB_USER! )

"!MYSQL!" -u !DB_USER! -p!DB_PASS! -h 127.0.0.1 -P !MYSQL_PORT! -e "SELECT User,Host FROM mysql.user WHERE User='';" 2>nul | findstr /r "^\s*$" >nul
if errorlevel 1 ( echo [FAIL] anonymous accounts still present & set "FAILED=1" ) else ( echo [PASS] no anonymous accounts )

call "%~dp0..\scripts\install_mariadb.cmd" >nul 2>&1
if errorlevel 3 ( echo [PASS] duplicate install rejected ^(rc=3^) ) else ( echo [FAIL] duplicate install was not rejected & set "FAILED=1" )

echo [INFO] Stop/start rollback test...
sc stop MariaDB >nul
timeout /t 4 /nobreak >nul
sc query MariaDB | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo [FAIL] MariaDB still running after stop & set "FAILED=1" ) else ( echo [PASS] MariaDB stopped )
sc start MariaDB >nul
timeout /t 5 /nobreak >nul
sc query MariaDB | findstr /i "RUNNING" >nul
if errorlevel 1 ( echo [FAIL] MariaDB did not restart & set "FAILED=1" ) else ( echo [PASS] MariaDB restarted )

call "%~dp0..\scripts\common.cmd" log "test_mariadb result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
