@echo off
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=restart_mariadb.log"
call "%~dp0common.cmd"
call "%~dp0stop_mariadb.cmd"
if errorlevel 1 exit /b 1
call "%~dp0start_mariadb.cmd"
exit /b %errorlevel%
