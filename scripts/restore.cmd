@echo off
rem ==========================================================
rem  restore.cmd - Module 8 (Restore)
rem  Restores a backup created by backup.cmd. Usage:
rem      restore.cmd [path-to-backup.zip]
rem  Without an argument the most recent backup is restored.
rem  The archive is verified before anything is touched.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=restore.log"
call "%~dp0common.cmd" log "=== restore.cmd start ==="

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

set "BACKUP_DIR=!SERVER_INSTALL_PATH!\backup"
set "STAGE=%TEMP%\oziris_restore_stage"

set "ZIP=%~1"
if not defined ZIP (
    if not exist "!BACKUP_DIR!" (
        echo [ERROR] Backup folder does not exist: "!BACKUP_DIR!".
        exit /b 1
    )
    for /f "delims=" %%z in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!BACKUP_DIR!' -Filter 'backup_*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"') do set "ZIP=%%z"
    if not defined ZIP (
        echo [ERROR] No backups found in "!BACKUP_DIR!".
        exit /b 1
    )
)

if not exist "!ZIP!" (
    echo [ERROR] Backup file not found: "!ZIP!".
    exit /b 1
)

echo [INFO] Verifying archive integrity...
powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; try { $z = [System.IO.Compression.ZipFile]::OpenRead('!ZIP!'); $c = $z.Entries.Count; $z.Dispose(); if ($c -gt 0) { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Restore aborted - archive corrupt"
    echo [ERROR] Archive is corrupt or empty. Restore aborted.
    exit /b 1
)

if exist "!STAGE!" rmdir /s /q "!STAGE!"
mkdir "!STAGE!"

echo [INFO] Extracting backup...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!ZIP!' -DestinationPath '!STAGE!' -Force"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Extract failed"
    echo [ERROR] Failed to extract backup.
    rmdir /s /q "!STAGE!"
    exit /b 1
)

rem ----- database -----
set "SQL="
for /f "delims=" %%f in ('dir /b "!STAGE!\db\*.sql" 2^>nul') do set "SQL=!STAGE!\db\%%f"
if not defined SQL (
    echo [WARN] No SQL dump found in backup. Skipping database restore.
) else (
    sc query MariaDB >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] MariaDB service not installed. Cannot restore the database.
        rmdir /s /q "!STAGE!"
        exit /b 1
    )
    sc query MariaDB | findstr /i "RUNNING" >nul
    if errorlevel 1 (
        echo [INFO] Starting MariaDB...
        sc start MariaDB >nul
        timeout /t 5 /nobreak >nul
    )
    echo [INFO] Restoring database "!DB_NAME!" from "!SQL!"...
    "!SERVER_INSTALL_PATH!\mariadb\bin\mysql.exe" -u root -p!DB_ROOT_PASS! -h 127.0.0.1 -P !MYSQL_PORT! !DB_NAME! < "!SQL!"
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[ERROR] Database restore failed"
        echo [ERROR] Database restore failed.
        rmdir /s /q "!STAGE!"
        exit /b 1
    )
)

rem ----- configuration -----
if exist "!STAGE!\conf\server.ini" copy /y "!STAGE!\conf\server.ini" "!SERVER_PACK_ROOT!\config\server.ini" >nul
if exist "!STAGE!\conf\php.ini" copy /y "!STAGE!\conf\php.ini" "!SERVER_INSTALL_PATH!\php54\php.ini" >nul
if exist "!STAGE!\conf\my.ini" copy /y "!STAGE!\conf\my.ini" "!SERVER_INSTALL_PATH!\mariadb\my.ini" >nul
if exist "!STAGE!\conf\httpd.conf" copy /y "!STAGE!\conf\httpd.conf" "!SERVER_INSTALL_PATH!\apache24\conf\httpd.conf" >nul
if exist "!STAGE!\conf\vhost.conf" copy /y "!STAGE!\conf\vhost.conf" "!SERVER_INSTALL_PATH!\apache24\conf\vhost.conf" >nul
if exist "!STAGE!\conf\php.conf" copy /y "!STAGE!\conf\php.conf" "!SERVER_INSTALL_PATH!\apache24\conf\extra\php.conf" >nul

rmdir /s /q "!STAGE!"
call "%~dp0common.cmd" log "[OK] Restore completed from !ZIP!"
echo [OK] Restore completed from "!ZIP!".
exit /b 0
