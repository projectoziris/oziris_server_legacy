@echo off
rem Test: Admin Panel (deployed, files present, negative missing source)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_admin.log"
call "%~dp0..\scripts\common.cmd" log "=== test_admin.cmd ==="
set "FAILED=0"
set "ADMIN=!SERVER_INSTALL_PATH!\www\admin"

if not exist "!ADMIN!\index.php" ( echo [SKIP] Admin panel not deployed - deploy_admin.cmd required & exit /b 2 )

set "PHP=!SERVER_INSTALL_PATH!\php54\php.exe"
if exist "!PHP!" (
    for %%f in ("!ADMIN!\index.php" "!ADMIN!\login.php" "!ADMIN!\status.php" "!ADMIN!\lib\bootstrap.php") do (
        "!PHP!" -l "%%~f" >nul 2>&1
        if errorlevel 1 ( echo [FAIL] syntax error in %%~nxf & set "FAILED=1" ) else ( echo [PASS] %%~nxf is valid PHP )
    )
)

if exist "!ADMIN!\lib\pages\dashboard.php" ( echo [PASS] dashboard page present ) else ( echo [FAIL] dashboard page missing & set "FAILED=1" )
if exist "!ADMIN!\assets\admin.css" ( echo [PASS] stylesheet present ) else ( echo [FAIL] stylesheet missing & set "FAILED=1" )

set "SRC_MISSING="
if not exist "!SERVER_PACK_ROOT!\www\admin\index.php" set "SRC_MISSING=1"
call "%~dp0..\scripts\deploy_admin.cmd" >nul 2>&1
if errorlevel 2 ( echo [PASS] missing source rejected ^(rc=2^) ) else (
    if not defined SRC_MISSING ( echo [PASS] re-deploy ok ^(idempotent^) ) else ( echo [FAIL] missing source not rejected & set "FAILED=1" )
)

call "%~dp0..\scripts\common.cmd" log "test_admin result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0