@echo off
setlocal EnableDelayedExpansion
call "%~dp0common.cmd"
sc query Apache24 >nul 2>&1
if errorlevel 1 ( echo Apache24   : NOT INSTALLED & exit /b 3 )
sc query Apache24 | findstr /i "RUNNING" >nul
if not errorlevel 1 ( echo Apache24   : RUNNING & exit /b 0 )
echo Apache24   : STOPPED
exit /b 1
