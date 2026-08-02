@echo off
rem ==========================================================
rem  migrate_xampp.cmd - Module 10 (Migration)
rem  Imports an existing XAMPP installation into OZI-RIS Server:
rem    - htdocs    -> install\www
rem    - databases -> MariaDB (all databases)
rem    - php.ini   -> php54\php.ini with paths auto-fixed
rem    - VirtualHost blocks -> apache24\conf\vhost.conf
rem  Usage: migrate_xampp.cmd [XAMPP path] [-NoDb]
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=migrate_xampp.log"
call "%~dp0common.cmd" log "=== migrate_xampp.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "XAMPP=%~1"
if not defined XAMPP set "XAMPP=C:\xampp"
set "NODB="
if "%~2"=="-NoDb" set "NODB=1"

if not exist "!XAMPP!\htdocs" (
    echo [ERROR] XAMPP not found at "!XAMPP!". Pass the correct path as the first argument.
    call "%~dp0common.cmd" log "[ERROR] XAMPP not found at !XAMPP!"
    exit /b 1
)

echo [INFO] Migrating from XAMPP at "!XAMPP!"...

echo [INFO] Copying htdocs to "!SERVER_INSTALL_PATH!\www"...
if not exist "!SERVER_INSTALL_PATH!\www" mkdir "!SERVER_INSTALL_PATH!\www"
xcopy /e /i /y "!XAMPP!\htdocs\*" "!SERVER_INSTALL_PATH!\www\" >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[WARN] htdocs copy reported errors"
    echo [WARN] htdocs copy completed with warnings.
)

set "SQL=%TEMP%\oziris_xampp_all.sql"
if not defined NODB (
    if exist "!XAMPP!\mysql\bin\mysqldump.exe" (
        echo [INFO] Dumping all databases from XAMPP MySQL...
        "!XAMPP!\mysql\bin\mysqldump.exe" -u root --all-databases --routines --triggers > "!SQL!" 2>nul
        if errorlevel 1 (
            call "%~dp0common.cmd" log "[WARN] XAMPP mysqldump failed (XAMPP MySQL running?)"
            echo [WARN] XAMPP MySQL dump failed. Is the XAMPP MySQL service running and root password empty?
        ) else (
            for %%f in ("!SQL!") do if %%~zf gtr 0 (
                echo [INFO] Importing databases into MariaDB...
                "!SERVER_INSTALL_PATH!\mariadb\bin\mysql.exe" -u root --password=!DB_ROOT_PASS! -h 127.0.0.1 -P !MYSQL_PORT! < "!SQL!"
                if errorlevel 1 (
                    call "%~dp0common.cmd" log "[WARN] Database import failed"
                    echo [WARN] Database import failed. See the dump at "!SQL!".
                ) else (
                    call "%~dp0common.cmd" log "[OK] Databases imported"
                    echo [OK] Databases imported.
                    del "!SQL!" >nul 2>&1
                )
            )
        )
    ) else (
        echo [WARN] XAMPP mysqldump not found - skipping database import.
    )
)

echo [INFO] Importing php.ini and VirtualHost configuration...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Migrate-Config.ps1" -XamppPath "!XAMPP!" -InstallPath "!SERVER_INSTALL_PATH!" -Mode Both
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Config migration failed"
    echo [ERROR] Configuration migration failed.
    exit /b 1
)

set "PHP_EXE=!SERVER_INSTALL_PATH!\php54\php.exe"
if exist "!PHP_EXE!" (
    "!PHP_EXE!" -v >nul 2>&1
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[WARN] Imported php.ini could not be loaded by PHP"
        echo [WARN] Imported php.ini cannot be loaded by PHP. Run configure_php.cmd to regenerate.
    )
)

set "HTTPD=!SERVER_INSTALL_PATH!\apache24\bin\httpd.exe"
if exist "!HTTPD!" (
    echo [INFO] Re-testing Apache configuration...
    "!HTTPD!" -t -f "!SERVER_INSTALL_PATH!\apache24\conf\httpd.conf" >nul 2>&1
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[ERROR] Apache config test failed after migration"
        echo [ERROR] Apache configuration test failed after migration. Fix "!SERVER_INSTALL_PATH!\apache24\conf\vhost.conf".
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

call "%~dp0common.cmd" log "[OK] Migration from XAMPP completed"
echo.
echo [OK] Migration from XAMPP completed.
exit /b 0
