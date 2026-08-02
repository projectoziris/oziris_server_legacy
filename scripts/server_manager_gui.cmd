@echo off
rem ==========================================================
rem  server_manager_gui.cmd - Launch the GUI control panel
rem  Wraps server_manager_gui.ps1 (PowerShell + WinForms).
rem  The panel self-elevates when needed.
rem ==========================================================
setlocal
set "COMMON_LOG_FILE=server_manager.log"
call "%~dp0common.cmd"

where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell not found. GUI control panel cannot start.
    exit /b 1
)

start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0server_manager_gui.ps1"
exit /b 0
