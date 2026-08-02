@echo off
rem ==========================================================
rem  install_php.cmd - Module 3 (PHP 5.4)
rem  Copies the PHP 5.4 distribution into the install path and
rem  runs configure_php.cmd to generate php.ini + php.conf.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=install_php.log"
call "%~dp0common.cmd" log "=== install_php.cmd start ==="
call "%~dp0common.cmd" log "Install path: %SERVER_INSTALL_PATH%"

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "PHP_SRC_EXE="
for /f "delims=" %%f in ('dir /b /s "!SERVER_PACK_ROOT!\php54\php.exe" 2^>nul') do if not defined PHP_SRC_EXE set "PHP_SRC_EXE=%%~f"
if not defined PHP_SRC_EXE (
    echo [ERROR] PHP binary not found. Place the PHP 5.4 Thread Safe ^(VC9 x86^) distribution into "%SERVER_PACK_ROOT%\php54".
    call "%~dp0common.cmd" log "[ERROR] php54\php.exe not found"
    exit /b 2
)

for %%i in ("!PHP_SRC_EXE!\..") do set "PHP_SRC=%%~fi"
set "PHP_DIR=!SERVER_INSTALL_PATH!\php54"
echo [INFO] PHP source : !PHP_SRC!
echo [INFO] PHP target : !PHP_DIR!

if not exist "!SERVER_INSTALL_PATH!" mkdir "!SERVER_INSTALL_PATH!"
if not exist "!PHP_DIR!" mkdir "!PHP_DIR!"

echo [INFO] Copying PHP binaries...
xcopy /e /i /y "!PHP_SRC!\*" "!PHP_DIR!\" >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] xcopy of PHP failed"
    echo [ERROR] Failed to copy PHP binaries.
    exit /b 1
)

call "%~dp0configure_php.cmd"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] configure_php failed"
    echo [ERROR] PHP configuration failed.
    exit /b 1
)

call "%~dp0common.cmd" log "[OK] PHP installed"
echo [OK] PHP 5.4 installed and configured.
exit /b 0
