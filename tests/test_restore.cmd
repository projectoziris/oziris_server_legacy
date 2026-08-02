@echo off
rem Test: Restore (refuses corrupt archive, restores latest backup)
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=test_restore.log"
call "%~dp0..\scripts\common.cmd" log "=== test_restore.cmd ==="
set "FAILED=0"
set "BACKUP_DIR=!SERVER_INSTALL_PATH!\backup"

if not exist "!SERVER_INSTALL_PATH!\mariadb\bin\mysql.exe" ( echo [SKIP] MariaDB not installed - restore cannot run & exit /b 2 )

set "FAKE=%TEMP%\oziris_fake_backup.zip"
echo not a zip > "!FAKE!"
call "%~dp0..\scripts\restore.cmd" "!FAKE!" >nul 2>&1
if errorlevel 1 ( echo [PASS] corrupt archive refused ^(rc=!errorlevel!^) ) else ( echo [FAIL] corrupt archive was applied & set "FAILED=1" )
del "!FAKE!" >nul 2>&1

set "NEWEST="
for /f "delims=" %%z in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!BACKUP_DIR!' -Filter 'backup_*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"') do set "NEWEST=%%z"
if defined NEWEST (
    call "%~dp0..\scripts\restore.cmd" "!NEWEST!" >nul 2>&1
    if errorlevel 1 ( echo [FAIL] restore of valid backup failed & set "FAILED=1" ) else ( echo [PASS] latest backup restored ^(!NEWEST!^) )
) else (
    echo [WARN] no backup to restore - run test_backup.cmd first
)

call "%~dp0..\scripts\common.cmd" log "test_restore result=!FAILED!"
if "!FAILED!"=="1" exit /b 1
exit /b 0
