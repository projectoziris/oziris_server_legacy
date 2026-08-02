@echo off
rem ==========================================================
rem  install_apache.cmd - Module 2 (Apache 2.4)
rem  Extracts, configures, registers and starts the Apache
rem  Windows service. Idempotent when run through the installer.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=install_apache.log"
call "%~dp0common.cmd" log "=== install_apache.cmd start ==="
call "%~dp0common.cmd" log "Install path: %SERVER_INSTALL_PATH%"

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

sc query Apache24 >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Apache service already installed. Use remove_apache.cmd first.
    call "%~dp0common.cmd" log "[INFO] Apache24 service already exists"
    exit /b 3
)

set "HTTPD_BIN="
set "BIN_DIR="
for /f "delims=" %%f in ('dir /b /s "!SERVER_PACK_ROOT!\apache\httpd.exe" 2^>nul') do if not defined HTTPD_BIN (
    set "HTTPD_BIN=%%~f"
    set "BIN_DIR=%%~dpf"
)
if not defined HTTPD_BIN (
    echo [ERROR] Apache binary not found. Place the Apache 2.4 distribution into "%SERVER_PACK_ROOT%\apache".
    call "%~dp0common.cmd" log "[ERROR] apache\httpd.exe not found"
    exit /b 2
)

for %%i in ("!BIN_DIR!\..") do set "APACHE_SRC=%%~fi"
set "APACHE_DEST=!SERVER_INSTALL_PATH!\apache24"
echo [INFO] Apache source : !APACHE_SRC!
echo [INFO] Apache target : !APACHE_DEST!

if not exist "!SERVER_INSTALL_PATH!" mkdir "!SERVER_INSTALL_PATH!"
if not exist "!SERVER_INSTALL_PATH!\logs" mkdir "!SERVER_INSTALL_PATH!\logs"
if not exist "!APACHE_DEST!" mkdir "!APACHE_DEST!"

echo [INFO] Copying Apache binaries...
xcopy /e /i /y "!APACHE_SRC!\*" "!APACHE_DEST!\" >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] xcopy of Apache failed"
    echo [ERROR] Failed to copy Apache binaries.
    exit /b 1
)

set "MAP=%TEMP%\oziris_apache_%RANDOM%.map"
> "%MAP%" echo @@SERVER_ROOT@@=!APACHE_DEST!
>> "%MAP%" echo @@PORT@@=!APACHE_PORT!
>> "%MAP%" echo @@WWW_ROOT@@=!SERVER_INSTALL_PATH!\www
>> "%MAP%" echo @@PMA_ROOT@@=!SERVER_INSTALL_PATH!\phpmyadmin

echo [INFO] Generating httpd.conf...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Expand-Config.ps1" -Template "!SERVER_PACK_ROOT!\config\apache\httpd.conf.tpl" -Output "!APACHE_DEST!\conf\httpd.conf" -MapFile "!MAP!"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] httpd.conf generation failed"
    echo [ERROR] Failed to generate httpd.conf.
    del "%MAP%" >nul 2>&1
    exit /b 1
)

echo [INFO] Generating vhost.conf...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Expand-Config.ps1" -Template "!SERVER_PACK_ROOT!\config\apache\vhost.conf.tpl" -Output "!APACHE_DEST!\conf\vhost.conf" -MapFile "!MAP!"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] vhost.conf generation failed"
    echo [ERROR] Failed to generate vhost.conf.
    del "%MAP%" >nul 2>&1
    exit /b 1
)
del "%MAP%" >nul 2>&1

if not exist "!APACHE_DEST!\conf\extra" mkdir "!APACHE_DEST!\conf\extra"
> "!APACHE_DEST!\conf\extra\php.conf" echo # PHP integration placeholder - replaced by configure_php.cmd

echo [INFO] Deploying web root...
if not exist "!SERVER_INSTALL_PATH!\www" mkdir "!SERVER_INSTALL_PATH!\www"
xcopy /e /i /y "!SERVER_PACK_ROOT!\www\*" "!SERVER_INSTALL_PATH!\www\" >nul

echo [INFO] Testing Apache configuration...
"!APACHE_DEST!\bin\httpd.exe" -t -f "!APACHE_DEST!\conf\httpd.conf"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] httpd -t failed"
    echo [ERROR] Apache configuration test failed. Review "!APACHE_DEST!\logs\error.log".
    exit /b 1
)

echo [INFO] Registering Apache24 service...
"!APACHE_DEST!\bin\httpd.exe" -k install -n Apache24 -f "!APACHE_DEST!\conf\httpd.conf"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] httpd -k install failed"
    echo [ERROR] Failed to register Apache24 service.
    exit /b 1
)

sc config Apache24 start= auto >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] sc config start=auto failed"
    echo [ERROR] Failed to set Apache24 to auto-start.
    exit /b 1
)

echo [INFO] Starting Apache24 service...
sc start Apache24 >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] sc start Apache24 failed"
    echo [ERROR] Failed to start Apache24 service.
    exit /b 1
)
ping -n 4 127.0.0.1 >nul

echo [INFO] Testing HTTP response on port %APACHE_PORT%...
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:%APACHE_PORT%/' -UseBasicParsing -TimeoutSec 15; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] HTTP test on port %APACHE_PORT% failed"
    echo [ERROR] Apache started but did not answer on port %APACHE_PORT%.
    exit /b 1
)

call "%~dp0common.cmd" log "[OK] Apache installed and running"
echo.
echo [OK] Apache 2.4 installed and running on port %APACHE_PORT%.
echo      Home: http://localhost:%APACHE_PORT%/
exit /b 0
