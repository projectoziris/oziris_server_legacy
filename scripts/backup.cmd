@echo off
rem ==========================================================
rem  backup.cmd - Module 8 (Backup)
rem  Creates a timestamped compressed archive containing a
rem  mysqldump of the application database plus all server
rem  configuration files. Verifies archive integrity and applies
rem  the retention policy from config\server.ini.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=backup.log"
call "%~dp0common.cmd" log "=== backup.cmd start ==="

set "BACKUP_DIR=!SERVER_INSTALL_PATH!\backup"
set "DUMP=!SERVER_INSTALL_PATH!\mariadb\bin\mysqldump.exe"
set "STAGE=%TEMP%\oziris_backup_stage"

if not exist "!DUMP!" (
    echo [ERROR] mysqldump not found. Install MariaDB first.
    call "%~dp0common.cmd" log "[ERROR] mysqldump not found"
    exit /b 3
)

if not exist "!BACKUP_DIR!" mkdir "!BACKUP_DIR!"
if exist "!STAGE!" rmdir /s /q "!STAGE!"
mkdir "!STAGE!\db"
mkdir "!STAGE!\conf"

for /f "delims=" %%t in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HHmmss'"') do set "TS=%%t"
set "SQL=!STAGE!\db\!DB_NAME!.sql"
set "ZIP=!BACKUP_DIR!\backup_!TS!.zip"

echo [INFO] Dumping database "!DB_NAME!"...
"!DUMP!" -u !DB_USER! -p!DB_PASS! -h 127.0.0.1 -P !MYSQL_PORT! --default-character-set=utf8 --routines --triggers !DB_NAME! > "!SQL!" 2>nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] mysqldump failed"
    echo [ERROR] Database dump failed. Is MariaDB running?
    rmdir /s /q "!STAGE!"
    exit /b 1
)
for %%f in ("!SQL!") do if %%~zf equ 0 (
    call "%~dp0common.cmd" log "[ERROR] mysqldump produced an empty file"
    echo [ERROR] Database dump is empty.
    rmdir /s /q "!STAGE!"
    exit /b 1
)

echo [INFO] Storing configuration files...
copy /y "!SERVER_PACK_ROOT!\config\server.ini" "!STAGE!\conf\server.ini" >nul
if exist "!SERVER_INSTALL_PATH!\php54\php.ini" copy /y "!SERVER_INSTALL_PATH!\php54\php.ini" "!STAGE!\conf\php.ini" >nul
if exist "!SERVER_INSTALL_PATH!\mariadb\my.ini" copy /y "!SERVER_INSTALL_PATH!\mariadb\my.ini" "!STAGE!\conf\my.ini" >nul
if exist "!SERVER_INSTALL_PATH!\apache24\conf\httpd.conf" copy /y "!SERVER_INSTALL_PATH!\apache24\conf\httpd.conf" "!STAGE!\conf\httpd.conf" >nul
if exist "!SERVER_INSTALL_PATH!\apache24\conf\vhost.conf" copy /y "!SERVER_INSTALL_PATH!\apache24\conf\vhost.conf" "!STAGE!\conf\vhost.conf" >nul
if exist "!SERVER_INSTALL_PATH!\apache24\conf\extra\php.conf" copy /y "!SERVER_INSTALL_PATH!\apache24\conf\extra\php.conf" "!STAGE!\conf\php.conf" >nul

echo [INFO] Compressing backup archive...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!STAGE!\*' -DestinationPath '!ZIP!' -CompressionLevel Optimal -Force"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Compress-Archive failed"
    echo [ERROR] Failed to create archive.
    rmdir /s /q "!STAGE!"
    exit /b 1
)

echo [INFO] Verifying archive integrity...
powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; try { $z = [System.IO.Compression.ZipFile]::OpenRead('!ZIP!'); $c = $z.Entries.Count; $z.Dispose(); if ($c -gt 0) { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Archive integrity check failed"
    echo [ERROR] Archive integrity check failed.
    rmdir /s /q "!STAGE!"
    exit /b 1
)

echo [INFO] Applying retention (keep !BACKUP_RETENTION! days)...
powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!BACKUP_DIR!' -Filter 'backup_*.zip' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-!BACKUP_RETENTION!) } | Remove-Item -Force"

rmdir /s /q "!STAGE!"
call "%~dp0common.cmd" log "[OK] Backup created: !ZIP!"
echo [OK] Backup created: !ZIP!
exit /b 0
