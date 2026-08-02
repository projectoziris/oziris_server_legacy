# OZI-RIS Server Pack - MariaDB my.ini template
# Placeholders are expanded by install_mariadb.cmd.
# Values: @@MDB_ROOT@@, @@MYSQL_PORT@@, @@MYSQL_DATA_DIR@@

[client]
port = @@MYSQL_PORT@@

[mysqld]
basedir = @@MDB_ROOT@@
datadir = @@MYSQL_DATA_DIR@@
port = @@MYSQL_PORT@@
skip-external-locking

character-set-server = utf8
collation-server = utf8_general_ci

innodb_buffer_pool_size = 512M
innodb_log_file_size = 64M
max_connections = 100
max_allowed_packet = 128M
; Legacy MYXSIR app relies on non-strict SQL mode (INSERTs omit NOT NULL
; columns without defaults, e.g. test.lmp). STRICT_TRANS_TABLES would
; reject these with "Field 'x' doesn't have a default value".
sql_mode = "NO_ENGINE_SUBSTITUTION"

log_error = @@MDB_ROOT@@/logs/mysql-error.log
slow_query_log = 1
slow_query_log_file = @@MDB_ROOT@@/logs/mysql-slow.log
long_query_time = 2

[mysqldump]
quick
max_allowed_packet = 256M
