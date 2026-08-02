@echo off
rem ==========================================================
rem  common.cmd - shared helpers for OZI-RIS Server Pack
rem  Include once at the top of every script:
rem      call "%~dp0common.cmd"
rem  It ALWAYS parses config\server.ini and defines:
rem      SERVER_PACK_ROOT, SERVER_INSTALL_PATH, APACHE_PORT,
rem      MYSQL_PORT, DB_NAME, DB_USER, DB_PASS, DB_ROOT_PASS,
rem      PHP_TIMEZONE, PHP_MEMORY_LIMIT, PHP_UPLOAD_MAX,
rem      BACKUP_RETENTION, LOG_DIR, CFG_FILE
rem  Logging helper:
rem      call "%~dp0common.cmd" log "message text"
rem ==========================================================

set "SERVER_PACK_ROOT=%~dp0.."
set "CFG_FILE=%SERVER_PACK_ROOT%\config\server.ini"
set "LOG_DIR=%SERVER_PACK_ROOT%\logs"
if not defined COMMON_LOG_FILE set "COMMON_LOG_FILE=server.log"

if not exist "%CFG_FILE%" (
    echo [ERROR] Missing configuration file: "%CFG_FILE%"
    exit /b 1
)

for /f "usebackq eol=; tokens=1,* delims==" %%a in ("%CFG_FILE%") do (
    if /i not "%%~a"=="[server]" (
        set "CFG_%%~a=%%~b"
    )
)

set "SERVER_INSTALL_PATH=%CFG_install_path%"
set "APACHE_PORT=%CFG_apache_port%"
set "MYSQL_PORT=%CFG_mysql_port%"
set "DB_ROOT_PASS=%CFG_db_root_pass%"
set "DB_NAME=%CFG_db_name%"
set "DB_USER=%CFG_db_user%"
set "DB_PASS=%CFG_db_pass%"
set "PHP_MEMORY_LIMIT=%CFG_memory_limit%"
set "PHP_UPLOAD_MAX=%CFG_upload_max_size%"
set "PHP_TIMEZONE=%CFG_timezone%"
set "BACKUP_RETENTION=%CFG_backup_retention%"

if "%~1"=="log" goto :log
if "%~1"=="now" goto :now
goto :eof

:log
set "LF=%COMMON_LOG_FILE%"
if not defined LF set "LF=server.log"
if not exist "%~dp0..\logs" mkdir "%~dp0..\logs"
>> "%~dp0..\logs\%LF%" echo [%date% %time%] %~2
exit /b 0

:now
echo %date% %time%
exit /b 0
