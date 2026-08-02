@echo off
rem ==========================================================
rem  configure_php.cmd - Module 3 (PHP 5.4)
rem  Generates php.ini and the Apache php.conf integration from
rem  the current config\server.ini. Safe to re-run.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=configure_php.log"
call "%~dp0common.cmd" log "=== configure_php.cmd start ==="

set "PHP_DIR=!SERVER_INSTALL_PATH!\php54"
set "PHP_EXE=!PHP_DIR!\php.exe"
set "APACHE_DEST=!SERVER_INSTALL_PATH!\apache24"

if not exist "!PHP_EXE!" (
    echo [ERROR] PHP is not installed. Run install_php.cmd first.
    call "%~dp0common.cmd" log "[ERROR] php.exe not found at !PHP_EXE!"
    exit /b 3
)

if not exist "!PHP_DIR!\tmp" mkdir "!PHP_DIR!\tmp"
if not exist "!PHP_DIR!\logs" mkdir "!PHP_DIR!\logs"

rem Copy the root dependency DLLs (libeay32, ssleay32, libssh2, ...) into
rem apache24\bin (httpd.exe's application directory, first in its DLL search
rem order) AND ext\. The CLI finds them via php.exe's own directory, but the
rem httpd process does not search the PHP root or ext\; without the copies the
rem openssl/curl extensions fail to load under mod_php ("Unable to load dynamic
rem library ... The specified module could not be found").
for %%d in ("!PHP_DIR!\*.dll") do (
    if /i not "%%~nxd"=="php5ts.dll" if /i not "%%~nxd"=="php5apache2_2.dll" if /i not "%%~nxd"=="php5apache2_2_filter.dll" if /i not "%%~nxd"=="php5apache2_4.dll" if /i not "%%~nxd"=="php5nsapi.dll" (
        copy /y "%%d" "!PHP_DIR!\ext\" >nul 2>&1
        if exist "!APACHE_DEST!\bin" copy /y "%%d" "!APACHE_DEST!\bin\" >nul 2>&1
    )
)

rem Compute post_max_size = upload_max_size + 32M
for /f "delims=MmGg tokens=1" %%a in ("!PHP_UPLOAD_MAX!") do set "UP=%%a"
set /a POST=UP+32
set "PHP_POST_MAX=!POST!M"

set "MAP=%TEMP%\oziris_php_%RANDOM%.map"
> "%MAP%" echo @@PHP_ROOT@@=!PHP_DIR!
>> "%MAP%" echo @@TIMEZONE@@=!PHP_TIMEZONE!
>> "%MAP%" echo @@MEMORY_LIMIT@@=!PHP_MEMORY_LIMIT!
>> "%MAP%" echo @@UPLOAD_MAX@@=!PHP_UPLOAD_MAX!
>> "%MAP%" echo @@POST_MAX@@=!PHP_POST_MAX!

echo [INFO] Generating php.ini...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Expand-Config.ps1" -Template "!SERVER_PACK_ROOT!\config\php\php.ini.tpl" -Output "!PHP_DIR!\php.ini" -MapFile "!MAP!"
if errorlevel 1 (
    del "%MAP%" >nul 2>&1
    call "%~dp0common.cmd" log "[ERROR] php.ini generation failed"
    echo [ERROR] Failed to generate php.ini.
    exit /b 1
)
del "%MAP%" >nul 2>&1

echo [INFO] Verifying PHP CLI and extensions...
"!PHP_EXE!" -v >nul 2>&1
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] php.exe could not start (VC9 runtime missing?)"
    echo [ERROR] PHP cannot start. Install the Microsoft Visual C++ 2008 SP1 redistributable ^(x86^).
    exit /b 1
)

set "MISSING="
for %%m in (mysqli gd openssl curl mbstring fileinfo) do (
    "!PHP_EXE!" -m 2>nul | findstr /i "%%m" >nul
    if errorlevel 1 set "MISSING=!MISSING! %%m"
)
if defined MISSING (
    call "%~dp0common.cmd" log "[ERROR] Missing PHP extensions:!MISSING!"
    echo [ERROR] Missing PHP extensions:!MISSING!
    exit /b 1
)

rem Write Apache integration if Apache is installed.
if exist "!APACHE_DEST!\conf\extra" (
    set "MAP2=%TEMP%\oziris_php_%RANDOM%.map"
    > "!MAP2!" echo @@PHP_ROOT@@=!PHP_DIR!
    echo [INFO] Generating Apache PHP integration ^(php.conf^)...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Expand-Config.ps1" -Template "!SERVER_PACK_ROOT!\config\php\php.conf.tpl" -Output "!APACHE_DEST!\conf\extra\php.conf" -MapFile "!MAP2!"
    if errorlevel 1 (
        del "!MAP2!" >nul 2>&1
        call "%~dp0common.cmd" log "[ERROR] php.conf generation failed"
        echo [ERROR] Failed to generate php.conf.
        exit /b 1
    )
    del "!MAP2!" >nul 2>&1

    sc query Apache24 >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Re-testing Apache configuration...
        "!APACHE_DEST!\bin\httpd.exe" -t -f "!APACHE_DEST!\conf\httpd.conf" >nul 2>&1
        if errorlevel 1 (
            call "%~dp0common.cmd" log "[ERROR] httpd -t failed after PHP integration"
            echo [ERROR] Apache configuration test failed after PHP integration.
            exit /b 1
        )
        sc query Apache24 | findstr /i "RUNNING" >nul
        if not errorlevel 1 (
            echo [INFO] Restarting Apache24...
            sc stop Apache24 >nul
            ping -n 4 127.0.0.1 >nul
            sc start Apache24 >nul
        )
    )
)

call "%~dp0common.cmd" log "[OK] PHP configured"
echo [OK] PHP 5.4 configured.
exit /b 0
