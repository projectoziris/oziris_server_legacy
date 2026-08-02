@echo off
rem ==========================================================
rem  deploy_phpmyadmin.cmd - Module 5 (phpMyAdmin 4.4)
rem  Copies phpMyAdmin into the install path and generates a
rem  hardened config.inc.php bound to the local MariaDB server.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=deploy_phpmyadmin.log"
call "%~dp0common.cmd" log "=== deploy_phpmyadmin.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "PMA_INDEX="
for /f "delims=" %%f in ('dir /b /s "!SERVER_PACK_ROOT!\phpmyadmin\index.php" 2^>nul') do if not defined PMA_INDEX set "PMA_INDEX=%%~f"
if not defined PMA_INDEX (
    echo [ERROR] phpMyAdmin not found. Place the phpMyAdmin 4.4 distribution into "%SERVER_PACK_ROOT%\phpmyadmin".
    call "%~dp0common.cmd" log "[ERROR] phpmyadmin\index.php not found"
    exit /b 2
)

for %%i in ("!PMA_INDEX!\..") do set "PMA_SRC=%%~fi"
set "PMA_DEST=!SERVER_INSTALL_PATH!\phpmyadmin"
echo [INFO] phpMyAdmin source : !PMA_SRC!
echo [INFO] phpMyAdmin target : !PMA_DEST!

if not exist "!SERVER_INSTALL_PATH!" mkdir "!SERVER_INSTALL_PATH!"
if not exist "!PMA_DEST!" mkdir "!PMA_DEST!"

echo [INFO] Copying phpMyAdmin...
xcopy /e /i /y "!PMA_SRC!\*" "!PMA_DEST!\" >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] xcopy of phpMyAdmin failed"
    echo [ERROR] Failed to copy phpMyAdmin.
    exit /b 1
)

for /f "delims=" %%r in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "BLOWFISH=%%r"

set "MAP=%TEMP%\oziris_pma_%RANDOM%.map"
> "%MAP%" echo @@BLOWFISH@@=!BLOWFISH!
>> "%MAP%" echo @@MYSQL_PORT@@=!MYSQL_PORT!
>> "%MAP%" echo @@DB_USER@@=!DB_USER!
>> "%MAP%" echo @@DB_PASS@@=!DB_PASS!

echo [INFO] Generating config.inc.php...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Expand-Config.ps1" -Template "!SERVER_PACK_ROOT!\config\phpmyadmin\config.inc.php.tpl" -Output "!PMA_DEST!\config.inc.php" -MapFile "!MAP!"
if errorlevel 1 (
    del "%MAP%" >nul 2>&1
    call "%~dp0common.cmd" log "[ERROR] config.inc.php generation failed"
    echo [ERROR] Failed to generate config.inc.php.
    exit /b 1
)
del "%MAP%" >nul 2>&1

rem Remove the sample config to prevent accidental override.
if exist "!PMA_DEST!\config.sample.inc.php" del "!PMA_DEST!\config.sample.inc.php" >nul

rem Syntax check if PHP is installed.
set "PHP_EXE=!SERVER_INSTALL_PATH!\php54\php.exe"
if exist "!PHP_EXE!" (
    "!PHP_EXE!" -l "!PMA_DEST!\config.inc.php" >nul 2>&1
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[ERROR] config.inc.php PHP lint failed"
        echo [ERROR] Generated config.inc.php failed PHP syntax check.
        exit /b 1
    )
)

call "%~dp0common.cmd" log "[OK] phpMyAdmin deployed"
echo [OK] phpMyAdmin deployed at http://localhost:%APACHE_PORT%/phpmyadmin/
exit /b 0
