@echo off
rem Test: config parsing (positive / negative / restore)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_config.log"
call "%~dp0..\scripts\common.cmd" log "=== test_config.cmd ==="
set "FAILED=0"

if not defined SERVER_INSTALL_PATH ( echo [FAIL] server.ini not parsed ^(install_path^) & set "FAILED=1" ) else ( echo [PASS] install_path = !SERVER_INSTALL_PATH! )
if not defined APACHE_PORT ( echo [FAIL] server.ini not parsed ^(apache_port^) & set "FAILED=1" ) else ( echo [PASS] apache_port = !APACHE_PORT! )
if not defined MYSQL_PORT ( echo [FAIL] server.ini not parsed ^(mysql_port^) & set "FAILED=1" ) else ( echo [PASS] mysql_port = !MYSQL_PORT! )
if not defined DB_NAME ( echo [FAIL] server.ini not parsed ^(db_name^) & set "FAILED=1" ) else ( echo [PASS] db_name = !DB_NAME! )

set "CFG=%~dp0..\config\server.ini"
ren "%CFG%" server.ini.bak
if exist "%CFG%.bak" (
    cmd /c "call "%~dp0..\scripts\common.cmd"" >nul 2>&1
    if errorlevel 1 ( echo [PASS] missing server.ini rejected ^(rc=!errorlevel!^) ) else ( echo [FAIL] missing server.ini not detected & set "FAILED=1" )
    ren "%CFG%.bak" server.ini
) else (
    echo [FAIL] could not rename server.ini for negative test
    set "FAILED=1"
)

cmd /c "call "%~dp0..\scripts\common.cmd"" >nul 2>&1
if errorlevel 1 ( echo [FAIL] config not restored after negative test & set "FAILED=1" ) else ( echo [PASS] config restored and re-parsed )

call "%~dp0..\scripts\common.cmd" log "test_config result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
