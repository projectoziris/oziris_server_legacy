@echo off
rem ==========================================================
rem  install_mariadb.cmd - Module 4 (MariaDB 10.1)
rem  Copies MariaDB, initializes the data directory, registers
rem  the MariaDB Windows service, hardens accounts, creates the
rem  application database and the backup folder.
rem ==========================================================
setlocal EnableDelayedExpansion
set "COMMON_LOG_FILE=install_mariadb.log"
call "%~dp0common.cmd" log "=== install_mariadb.cmd start ==="
call "%~dp0common.cmd" log "Install path: %SERVER_INSTALL_PATH%"

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Administrative rights are required. Run as Administrator.
    call "%~dp0common.cmd" log "[ERROR] Not running as administrator"
    exit /b 1
)

sc query MariaDB >nul 2>&1
if not errorlevel 1 (
    echo [INFO] MariaDB service already installed. Use remove_mariadb.cmd first.
    call "%~dp0common.cmd" log "[INFO] MariaDB service already exists"
    exit /b 3
)

set "MYSQLD_EXE="
set "BIN_DIR="
for /f "delims=" %%f in ('dir /b /s "!SERVER_PACK_ROOT!\mariadb\mysqld.exe" 2^>nul') do if not defined MYSQLD_EXE (
    set "MYSQLD_EXE=%%~f"
    set "BIN_DIR=%%~dpf"
)
if not defined MYSQLD_EXE (
    echo [ERROR] MariaDB binary not found. Place the MariaDB 10.1 distribution into "%SERVER_PACK_ROOT%\mariadb".
    call "%~dp0common.cmd" log "[ERROR] mariadb\mysqld.exe not found"
    exit /b 2
)

for %%i in ("!BIN_DIR!\..") do set "MDB_SRC=%%~fi"
set "MDB_DEST=!SERVER_INSTALL_PATH!\mariadb"
set "MDB_DATA=!MDB_DEST!\data"
echo [INFO] MariaDB source : !MDB_SRC!
echo [INFO] MariaDB target : !MDB_DEST!

if not exist "!SERVER_INSTALL_PATH!" mkdir "!SERVER_INSTALL_PATH!"
if not exist "!MDB_DEST!" mkdir "!MDB_DEST!"
if not exist "!MDB_DEST!\logs" mkdir "!MDB_DEST!\logs"
if not exist "!SERVER_INSTALL_PATH!\backup" mkdir "!SERVER_INSTALL_PATH!\backup"

echo [INFO] Copying MariaDB binaries...
xcopy /e /i /y "!MDB_SRC!\*" "!MDB_DEST!\" >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] xcopy of MariaDB failed"
    echo [ERROR] Failed to copy MariaDB binaries.
    exit /b 1
)

set "MAP=%TEMP%\oziris_mdb_%RANDOM%.map"
> "%MAP%" echo @@MDB_ROOT@@=!MDB_DEST!
>> "%MAP%" echo @@MYSQL_PORT@@=!MYSQL_PORT!
>> "%MAP%" echo @@MYSQL_DATA_DIR@@=!MDB_DATA!

echo [INFO] Generating my.ini...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Expand-Config.ps1" -Template "!SERVER_PACK_ROOT!\config\mariadb\my.ini.tpl" -Output "!MDB_DEST!\my.ini" -MapFile "!MAP!"
if errorlevel 1 (
    del "%MAP%" >nul 2>&1
    call "%~dp0common.cmd" log "[ERROR] my.ini generation failed"
    echo [ERROR] Failed to generate my.ini.
    exit /b 1
)
del "%MAP%" >nul 2>&1

if exist "!MDB_DATA!\mysql" (
    echo [INFO] Data directory already initialized.
) else (
    echo [INFO] Initializing data directory...
    if not exist "!MDB_DATA!" mkdir "!MDB_DATA!"
    "!MDB_DEST!\bin\mysql_install_db.exe" --basedir="!MDB_DEST!" --datadir="!MDB_DATA!"
    if errorlevel 1 (
        call "%~dp0common.cmd" log "[ERROR] mysql_install_db failed"
        echo [ERROR] Failed to initialize the data directory.
        exit /b 1
    )
)

echo [INFO] Registering MariaDB service...
"!MDB_DEST!\bin\mysqld.exe" --install MariaDB --defaults-file="!MDB_DEST!\my.ini"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] mysqld --install failed"
    echo [ERROR] Failed to register MariaDB service.
    exit /b 1
)

sc config MariaDB start= auto >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] sc config MariaDB failed"
    echo [ERROR] Failed to configure MariaDB service.
    exit /b 1
)

echo [INFO] Starting MariaDB service...
sc start MariaDB >nul
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] sc start MariaDB failed"
    echo [ERROR] Failed to start MariaDB service. Check "!MDB_DEST!\logs\mysql-error.log".
    exit /b 1
)
timeout /t 6 /nobreak >nul

set "MYSQL=!MDB_DEST!\bin\mysql.exe"

echo [INFO] Setting root password...
"%MYSQL%" -u root --protocol=TCP -h 127.0.0.1 -P !MYSQL_PORT! -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('!DB_ROOT_PASS!'); SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('!DB_ROOT_PASS!'); SET PASSWORD FOR 'root'@'::1' = PASSWORD('!DB_ROOT_PASS!');"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Setting root password failed"
    echo [ERROR] Failed to set the root password.
    exit /b 1
)

echo [INFO] Creating database "!DB_NAME!" and user "!DB_USER!"...
"%MYSQL%" -u root --protocol=TCP -h 127.0.0.1 -P !MYSQL_PORT! -p!DB_ROOT_PASS! -e "CREATE DATABASE IF NOT EXISTS \`!DB_NAME!\` CHARACTER SET utf8 COLLATE utf8_general_ci; CREATE USER IF NOT EXISTS '!DB_USER!'@'localhost' IDENTIFIED BY '!DB_PASS!'; GRANT ALL PRIVILEGES ON \`!DB_NAME!\`.* TO '!DB_USER!'@'localhost'; DELETE FROM mysql.user WHERE user=''; DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;"
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] Database creation failed"
    echo [ERROR] Failed to create the application database.
    exit /b 1
)

echo [INFO] Verifying connection as "!DB_USER!"...
"%MYSQL%" -u !DB_USER! -p!DB_PASS! --protocol=TCP -h 127.0.0.1 -P !MYSQL_PORT! -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    call "%~dp0common.cmd" log "[ERROR] App user connection test failed"
    echo [ERROR] Application user could not connect to the database.
    exit /b 1
)

call "%~dp0common.cmd" log "[OK] MariaDB installed, database created"
echo [OK] MariaDB installed. Database "!DB_NAME!" ready.
exit /b 0
