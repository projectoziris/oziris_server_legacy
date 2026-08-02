@echo off
rem Test: PHP (extensions present, php.ini settings, negative missing binary)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_php.log"
call "%~dp0..\scripts\common.cmd" log "=== test_php.cmd ==="
set "FAILED=0"
set "PHP=!SERVER_INSTALL_PATH!\php54\php.exe"

if not exist "!PHP!" ( echo [SKIP] PHP not installed - install_php.cmd required & exit /b 2 )

for %%m in (mysqli gd openssl curl mbstring fileinfo) do (
    "!PHP!" -m 2>nul | findstr /i "%%m" >nul
    if errorlevel 1 ( echo [FAIL] extension %%m missing & set "FAILED=1" ) else ( echo [PASS] extension %%m loaded )
)

"!PHP!" -r "echo ini_get('display_errors'),'|',ini_get('memory_limit'),'|',ini_get('upload_max_filesize'),'|',ini_get('date.timezone');" > "%TEMP%\oziris_php_ini.txt" 2>&1
set /p INIVAL=<"%TEMP%\oziris_php_ini.txt"
del "%TEMP%\oziris_php_ini.txt" >nul 2>&1
echo !INIVAL! | findstr /i "Off" >nul
if errorlevel 1 ( echo [FAIL] display_errors is not Off & set "FAILED=1" ) else ( echo [PASS] display_errors = Off )
echo !INIVAL! | findstr /i "!PHP_MEMORY_LIMIT!" >nul
if errorlevel 1 ( echo [FAIL] memory_limit mismatch & set "FAILED=1" ) else ( echo [PASS] memory_limit = !PHP_MEMORY_LIMIT! )

set "MISSING_PHP="
if not exist "!SERVER_PACK_ROOT!\php54\php.exe" set "MISSING_PHP=1"
call "%~dp0..\scripts\install_php.cmd" >nul 2>&1
if errorlevel 2 ( echo [PASS] missing binary rejected ^(rc=2^) ) else (
    if not defined MISSING_PHP ( echo [PASS] install_php re-run ok ^(already present^) ) else ( echo [FAIL] missing binary not rejected & set "FAILED=1" )
)

call "%~dp0..\scripts\common.cmd" log "test_php result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
