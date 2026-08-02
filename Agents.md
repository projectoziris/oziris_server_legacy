# AGENTS.md

# OZI-RIS Server Pack

## Project Goal

Build a professional Windows server package for legacy PHP applications (primarily OZI-RIS).

This project replaces XAMPP with a modular, maintainable server distribution.

Target environment:

- Windows 10 Pro 22H2
- Legacy BIOS
- Apache 2.4
- PHP 5.4.45
- MariaDB 10.1
- phpMyAdmin 4.4
- Dell Precision T7400
- Dual Xeon E5420
- 16GB RAM recommended
- SSD storage
- Intranet only
- No Internet exposure

---

# Design Principles

1. No XAMPP dependency.

2. Every component is replaceable.

3. Everything must run as Windows Services.

4. One-click installation.

5. One-click uninstall.

6. One-click backup.

7. Easy migration from existing XAMPP installation.

8. Production ready.

9. Fully documented.

10. Every module must be independently testable.

---

# Folder Structure

```
OZI-RIS-ServerPack

apache/
php54/
mariadb/
phpmyadmin/

installer/

scripts/

config/

logs/

backup/

www/

docs/

tests/
```

---

# Development Rules

Every module must:

- compile/run independently
- include logging
- include error handling
- support rollback
- return proper exit code

Never hardcode paths.

Use configurable variables.

---

# Default Installation Path

```
C:\OZI-RIS-Server
```

Never assume another drive.

---

# Required Modules

## Module 1

Project skeleton

Status:
Completed

---

## Module 2

Apache Installation

Tasks

- extract apache
- install service
- configure httpd.conf
- configure VirtualHost
- test localhost
- write logs

Deliverables

install_apache.cmd

remove_apache.cmd

apache.conf

---

## Module 3

PHP

Tasks

Install PHP 5.4

Configure php.ini

Enable

mysqli

gd

openssl

curl

mbstring

fileinfo

Set

timezone

memory limit

upload size

error logging

---

## Module 4

MariaDB

Tasks

Silent install

Create Windows Service

Configure my.ini

Create database

Enable utf8

Create backup folder

---

## Module 5

phpMyAdmin

Tasks

Deploy

Configure config.inc.php

Secure defaults

Test login

---

## Module 6

Windows Services

Create

Apache24

MariaDB

Auto Start

Restart support

Stop support

Status detection

---

## Module 7

Firewall

Automatically create

TCP 80

TCP 3306

Verify

Remove during uninstall

---

## Module 8

Backup

Automatic database backup

Backup configuration

Compressed archive

Retention

Restore

Integrity verification

---

## Module 9

Health Check

Verify

Apache

PHP

MariaDB

Ports

Disk

RAM

CPU

Windows Service

Return

Healthy

Warning

Critical

---

## Module 10

Migration

Import existing XAMPP

htdocs

database

php.ini

Apache config

VirtualHost

No manual editing

---

## Module 11

Server Manager

Console application

Menu

Start

Stop

Restart

Backup

Restore

Logs

Status

phpMyAdmin

Health

Exit

---

## Module 12

Installer

One-click setup

Progress bar

Rollback

Logging

Verification

Desktop shortcut

Start Menu shortcut

---

# Coding Standard

Batch

Use

SETLOCAL

Exit codes

ErrorLevel

PowerShell

Only when Batch cannot achieve the goal.

PHP

PSR-2 compatible whenever possible.

No deprecated syntax outside PHP 5.4 compatibility.

---

# Logging

Every module writes

logs/module_name.log

Installer writes

logs/install.log

Uninstaller writes

logs/uninstall.log

---

# Configuration Files

config/server.ini

Contains

Installation path

Ports

Memory

Database name

Backup schedule

Timezone

---

# Documentation

Each completed module must update

/docs

with

Installation

Configuration

Troubleshooting

Rollback

---

# Testing

Every module requires

Positive test

Negative test

Rollback test

Regression test

---

# Security

Intranet only.

Disable unnecessary Apache modules.

Disable PHP error display.

Enable logging.

No anonymous database accounts.

No default passwords.

---

# Deliverables

Each module should contain

Source

Configuration

Documentation

Test script

Rollback script

No placeholder code.

No TODO comments.

No unfinished implementation.

---

# Workflow

Implement ONE module only.

Run self review.

Fix issues.

Update documentation.

Stop.

Wait for the next instruction.

Never implement multiple modules in one iteration.

---

# Current Progress

| Module | Status |
|--------|--------|
| 1  Skeleton          | Completed |
| 2  Apache            | Completed |
| 3  PHP               | Completed |
| 4  MariaDB           | Completed |
| 5  phpMyAdmin        | Completed |
| 6  Windows Services  | Completed |
| 7  Firewall          | Completed |
| 8  Backup            | Completed |
| 9  Health Check      | Completed |
| 10 Migration         | Completed |
| 11 Server Manager    | Completed |
| 12 Installer         | Completed |

All module source, configuration templates, documentation (`docs\`), and tests
(`tests\`) are in place. The installer (`installer\install.cmd`) is the entry point;
it requires the binary distributions documented in `docs\INSTALLATION.md`.
