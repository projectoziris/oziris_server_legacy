@echo off
rem Test: phpMyAdmin (config valid, deployed, negative missing distro)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_phpmyadmin.log"
call "%~dp0..\scripts\common.cmd" log "=== test_phpmyadmin.cmd ==="
set "FAILED=0"
set "PMA=!SERVER_INSTALL_PATH!\phpmyadmin"

if not exist "!PMA!\index.php" ( echo [SKIP] phpMyAdmin not deployed - deploy_phpmyadmin.cmd required & exit /b 2 )

if not exist "!PMA!\config.inc.php" ( echo [FAIL] config.inc.php missing & set "FAILED=1" ) else ( echo [PASS] config.inc.php present )
if exist "!PMA!\config.sample.inc.php" ( echo [FAIL] config.sample.inc.php still present & set "FAILED=1" ) else ( echo [PASS] sample config removed )

set "PHP=!SERVER_INSTALL_PATH!\php54\php.exe"
if exist "!PHP!" (
    "!PHP!" -l "!PMA!\config.inc.php" >nul 2>&1
    if errorlevel 1 ( echo [FAIL] config.inc.php is not valid PHP & set "FAILED=1" ) else ( echo [PASS] config.inc.php is valid PHP )
)

set "SRC_MISSING="
if not exist "!SERVER_PACK_ROOT!\phpmyadmin\index.php" set "SRC_MISSING=1"
call "%~dp0..\scripts\deploy_phpmyadmin.cmd" >nul 2>&1
if errorlevel 2 ( echo [PASS] missing distribution rejected ^(rc=2^) ) else (
    if not defined SRC_MISSING ( echo [PASS] re-deploy ok ^(regenerated config^) ) else ( echo [FAIL] missing distribution not rejected & set "FAILED=1" )
)

call "%~dp0..\scripts\common.cmd" log "test_phpmyadmin result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
