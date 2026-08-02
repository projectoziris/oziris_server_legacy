@echo off
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=restart_apache.log"
call "%~dp0common.cmd"
call "%~dp0stop_apache.cmd"
if errorlevel 1 exit /b 1
call "%~dp0start_apache.cmd"
exit /b %errorlevel%
