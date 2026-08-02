@echo off
rem ==========================================================
rem  server_manager.cmd - Module 11 (Server Manager)
rem  Interactive console menu for day-to-day management.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=server_manager.log"
call "%~dp0common.cmd"

net session >nul 2>&1
if errorlevel 1 (
    echo [WARN] Not running as Administrator. Start/Stop/Restart require elevation.
)

:menu
cls
echo.
echo  ================================================
echo   OZI-RIS Server Manager
echo  ================================================
echo   1. Start services
echo   2. Stop services
echo   3. Restart services
echo   4. Backup
echo   5. Restore
echo   6. View logs
echo   7. Status
echo   8. Open phpMyAdmin
echo   9. Health check
echo   0. Exit
echo  ================================================
choice /c 1234567890 /m "Select option"
set "M=!errorlevel!"
if "!M!"=="1" goto :start
if "!M!"=="2" goto :stop
if "!M!"=="3" goto :restart
if "!M!"=="4" goto :backup
if "!M!"=="5" goto :restore
if "!M!"=="6" goto :logs
if "!M!"=="7" goto :status
if "!M!"=="8" goto :pma
if "!M!"=="9" goto :health
exit /b 0

:start
call "%~dp0start_apache.cmd"
call "%~dp0start_mariadb.cmd"
goto :pause_menu

:stop
call "%~dp0stop_apache.cmd"
call "%~dp0stop_mariadb.cmd"
goto :pause_menu

:restart
call "%~dp0restart_apache.cmd"
call "%~dp0restart_mariadb.cmd"
goto :pause_menu

:backup
call "%~dp0backup.cmd"
goto :pause_menu

:restore
set /p "ZIP=Backup file path (Enter = latest): "
call "%~dp0restore.cmd" "!ZIP!"
goto :pause_menu

:logs
set "LOG_DIR=!SERVER_PACK_ROOT!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
echo.
echo  Log files in "!LOG_DIR!":
set "IDX=0"
for /f "delims=" %%f in ('dir /b /o-d "!LOG_DIR!\*.log" 2^>nul') do (
    set /a IDX+=1
    echo  [!IDX!] %%f
)
set /a IDX+=1
echo  [!IDX!] Open folder in Explorer
echo  [0] Back to menu
set /p "L=View log number: "
if "!L!"=="0" goto :menu
if "!L!"=="!IDX!" (
    explorer "!LOG_DIR!"
    goto :pause_menu
)
set "CNT=0"
for /f "delims=" %%f in ('dir /b /o-d "!LOG_DIR!\*.log" 2^>nul') do (
    set /a CNT+=1
    if "!CNT!"=="!L!" set "PICKED=%%f"
)
if defined PICKED (
    echo.
    echo  --- !PICKED! ^(last 30 lines^) ---
    powershell -NoProfile -Command "Get-Content -LiteralPath '!LOG_DIR!\!PICKED!' -Tail 30"
) else (
    echo [WARN] Invalid selection.
)
goto :pause_menu

:status
call "%~dp0status_apache.cmd"
call "%~dp0status_mariadb.cmd"
goto :pause_menu

:pma
echo [INFO] Opening phpMyAdmin...
start "" "http://localhost:!APACHE_PORT!/phpmyadmin/"
goto :pause_menu

:health
call "%~dp0health_check.cmd"
goto :pause_menu

:pause_menu
echo.
pause
goto :menu
