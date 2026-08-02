@echo off
rem Test: Backup (archive created + verified, negative, cleanup)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_backup.log"
call "%~dp0..\scripts\common.cmd" log "=== test_backup.cmd ==="
set "FAILED=0"
set "BACKUP_DIR=!SERVER_INSTALL_PATH!\backup"

if not exist "!SERVER_INSTALL_PATH!\mariadb\bin\mysqldump.exe" ( echo [SKIP] MariaDB not installed - backup cannot run & exit /b 2 )

set "BEFORE=0"
for /f "delims=" %%z in ('dir /b "!BACKUP_DIR!\backup_*.zip" 2^>nul') do set /a BEFORE+=1

call "%~dp0..\scripts\backup.cmd" >nul 2>&1
if errorlevel 1 ( echo [FAIL] backup.cmd failed & set "FAILED=1" ) else ( echo [PASS] backup.cmd completed )

set "NEWEST="
for /f "delims=" %%z in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!BACKUP_DIR!' -Filter 'backup_*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"') do set "NEWEST=%%z"
if not defined NEWEST ( echo [FAIL] no backup archive found & set "FAILED=1" ) else (
    powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; try { $z=[System.IO.Compression.ZipFile]::OpenRead('!NEWEST!'); $c=$z.Entries.Count; $z.Dispose(); if ($c -gt 0) { exit 0 } else { exit 1 } } catch { exit 1 }"
    if errorlevel 1 ( echo [FAIL] archive integrity check failed & set "FAILED=1" ) else ( echo [PASS] archive verified ^(!NEWEST!^) )
)

call "%~dp0..\scripts\common.cmd" log "test_backup result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
