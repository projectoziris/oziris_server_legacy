# PHP 5.4 Extension Dependency Audit — OZIRIS Server

Date: 2026-08-02
Scope: All PHP extensions enabled by `php.ini`, verified by direct PE binary
inspection (no assumptions). Server: OZIRIS Server (intranet, legacy).

---

## 1. Environment Summary

| Item | Value |
| ---- | ----- |
| Server name | OZIRIS Server |
| OS | Microsoft Windows 10 Pro 10.0.19045 (64-bit) |
| PHP version | 5.4.45 (cli) — built Sep 2 2015 |
| Thread safety | TS (enabled) |
| Architecture | x86 (I386) |
| Compiler | MSVC9 (Visual C++ 2008) |
| PHP extension build | API20100525,TS,VC9 |
| Apache | 2.4.68 (Win32) Apache Lounge VS18, Jun 17 2026 |
| phpMyAdmin | 4.4.15.10 |
| MariaDB | 10.1.48 |
| Install path | `C:\OZI-RIS-Server` |
| Web port | 8000 |

Note: This is the OZI-RIS Server Pack install, not XAMPP; binaries are the
official PHP 5.4.45 VC9 TS x86 distribution.

---

## 2. PHP Configuration Summary

`php.ini` located at `C:\OZI-RIS-Server\php54\php.ini`
`extension_dir = "C:\OZI-RIS-Server\php54\ext"`

### 2.1 Enabled extensions (php.ini)

```
extension=php_mysqli.dll
extension=php_pdo_mysql.dll
extension=php_gd2.dll
extension=php_openssl.dll
extension=php_curl.dll
extension=php_mbstring.dll
extension=php_fileinfo.dll
```

### 2.2 Disabled / available (present in ext\ but not enabled)

php_bz2, php_com_dotnet, php_enchant, php_exif, php_gettext, php_gmp,
php_imap, php_interbase, php_intl, php_ldap, php_mysql, php_oci8,
php_oci8_11g, php_pdo_firebird, php_pdo_oci, php_pdo_odbc, php_pdo_pgsql,
php_pdo_sqlite, php_pgsql, php_shmop, php_snmp, php_soap, php_sockets,
php_sqlite3, php_sybase_ct, php_tidy, php_xmlrpc, php_xsl

---

## 3. Extension Inventory (enabled set)

| Extension | DLL Exists | CLI Loaded | Web (mod_php) Loaded | Status |
| --------- | ---------- | ---------- | -------------------- | ------ |
| php_mysqli.dll | Yes | Yes | Yes | OK |
| php_pdo_mysql.dll | Yes | Yes | Yes | OK |
| php_gd2.dll | Yes | Yes | Yes | OK |
| php_openssl.dll | Yes | Yes | Yes | OK |
| php_curl.dll | Yes | Yes | Yes | OK |
| php_mbstring.dll | Yes | Yes | Yes | OK |
| php_fileinfo.dll | Yes | Yes | Yes | OK |

`php -m` also lists built-in static modules (curl, openssl, gd, mbstring,
fileinfo, mysqli are all listed under `[PHP Modules]`).

---

## 4. Actual DLL Dependencies (from binary import tables)

Dependencies were read directly from each DLL's PE import directory.

### 4.1 php_openssl.dll
Imports: php5ts.dll, SSLEAY32.dll, LIBEAY32.dll, WS2_32.dll, MSVCR90.dll, KERNEL32.dll

Dependency tree:
```
php_openssl.dll
  |-- php5ts.dll        (php54 root)            OK
  |-- SSLEAY32.dll      (php54 root + apache24\bin) OK
  |     `-- LIBEAY32.dll, MSVCR90.dll, KERNEL32.dll
  |-- LIBEAY32.dll      (php54 root + apache24\bin) OK
  |     `-- WSOCK32.dll, GDI32.dll, ADVAPI32.dll, USER32.dll, MSVCR90.dll, KERNEL32.dll
  |-- WS2_32.dll        (system)                OK
  |-- MSVCR90.dll       (VC9 runtime, WinSxS)   OK
  `-- KERNEL32.dll      (system)                OK
```

### 4.2 php_curl.dll
Imports: php5ts.dll, LIBEAY32.dll, WS2_32.dll, libssh2.dll, SSLEAY32.dll, WLDAP32.dll, KERNEL32.dll, MSVCR90.dll

Dependency tree:
```
php_curl.dll
  |-- php5ts.dll        (php54 root)            OK
  |-- LIBEAY32.dll      (php54 root + apache24\bin) OK
  |-- SSLEAY32.dll      (php54 root + apache24\bin) OK
  |-- libssh2.dll       (php54 root + apache24\bin) OK
  |     `-- WS2_32.dll, LIBEAY32.dll, KERNEL32.dll, USER32.dll, MSVCR90.dll
  |-- WS2_32.dll        (system)                OK
  |-- WLDAP32.dll       (system)                OK
  |-- MSVCR90.dll       (VC9 runtime, WinSxS)   OK
  `-- KERNEL32.dll      (system)                OK
```

### 4.3 php_mysqli.dll / php_pdo_mysql.dll
Imports: php5ts.dll, MSVCR90.dll, KERNEL32.dll (+ mysqlnd symbols from php5ts.dll). OK.

### 4.4 php_gd2.dll
Imports: php5ts.dll (libiconv, zlib symbols come from php5ts.dll), USER32.dll, GDI32.dll, KERNEL32.dll, MSVCR90.dll. OK.

### 4.5 php_mbstring.dll
Imports: php5ts.dll, MSVCR90.dll, KERNEL32.dll. OK.

### 4.6 php_fileinfo.dll
Imports: php5ts.dll, MSVCR90.dll, KERNEL32.dll. OK.

---

## 5. Missing DLL Report

### After remediation: none.

### Before remediation (root cause):

| DLL | Problem | Why |
| --- | ------- | --- |
| LIBEAY32.dll | Not found by httpd.exe process | Present only in php54 root / ext; not in httpd's DLL search path |
| SSLEAY32.dll | Not found by httpd.exe process | Same |
| libssh2.dll | Not found by httpd.exe process | Same |

Observed error (per-request, in `C:\OZI-RIS-Server\php54\logs\php-error.log` at
Apache start):

```
PHP Warning: PHP Startup: Unable to load dynamic library
'C:\OZI-RIS-Server\php54\ext\php_openssl.dll' - The specified module could not be found.
```

### Root Cause

- The **CLI** (php.exe) loads these because php.exe lives in the PHP root, so
  LIBEAY32/SSLEAY32/libssh2 are found in php.exe's own directory.
- **mod_php** runs inside httpd.exe, whose application directory is
  `apache24\bin`. Windows resolves php_openssl.dll's dependent DLLs using the
  *standard search order* (application directory first, then system dirs, then
  PATH). The PHP root and `ext\` are **not** on that path, so the OpenSSL/libssh2
  DLLs could not be located.
- There is **no** libcurl.dll dependency: libcurl is statically linked into
  php_curl.dll. The task's assumption of a separate libcurl.dll does not apply
  to this distribution.

### Repair (applied, idempotent)

Copied the **matching, same-version** DLLs from the PHP 5.4.45 distribution root
into `apache24\bin` (httpd.exe's application directory):

- libeay32.dll
- ssleay32.dll
- libssh2.dll

Verified by SHA-256: copied files are byte-identical to the originals (MATCH).
`configure_php.cmd` was updated so a re-run (or a fresh install) performs this
copy automatically (targets both `apache24\bin` and `ext\`).

---

## 6. Architecture Compatibility Report

| Component | Architecture | Compatible? |
| --------- | ------------ | ----------- |
| PHP 5.4.45 | x86 | Yes |
| php_openssl.dll / php_curl.dll | x86 | Yes |
| libeay32.dll / ssleay32.dll / libssh2.dll | x86 | Yes |
| Apache 2.4.68 (Win32) | x86 | Yes |
| MariaDB 10.1.48 | x64 (server, out of PHP process) | Yes |
| Windows 10 Pro | x64 (host; runs x86 via WOW64) | Yes |

No architecture mismatches. All x86 binaries matched. (MariaDB is x64 but is a
separate process; php_mysqli/pdo_mysql use the mysqlnd client built into
php5ts.dll, so no client-server bitness issue.)

---

## 7. Visual C++ Runtime Verification

- PHP 5.4.45 is **VC9 (MSVC9 / Visual C++ 2008)**, so the runtime is
  **MSVCR90.dll**, not MSVCR100/MSVCP100.
- All seven enabled extensions import `MSVCR90.dll` (confirmed in import
  tables). No extension imports MSVCR100.dll / MSVCP100.dll.
- MSVCR90.dll is installed in WinSxS:
  - `x86_microsoft.vc90.crt_..._9.0.30729.6161`
  - `x86_microsoft.vc90.crt_..._9.0.30729.9625`
- Loadability confirmed at runtime: all extensions load under both CLI and
  mod_php.

Result: correct runtime present. No newer runtime is required or recommended.

---

## 8. OpenSSL Verification

- Libraries: libeay32.dll, ssleay32.dll (OpenSSL 0.9.8zf, 19 Mar 2015 — the
  build bundled with PHP 5.4.45).
- Exports: php_openssl.dll imports SSLEAY32/LIBEAY32 **by ordinal**; CLI load
  success proves the exported ordinals resolve. Loadability confirmed at runtime.
- Version reported by the running extension:
  `OPENSSL_VERSION_TEXT = OpenSSL 0.9.8zf 19 Mar 2015`.
- No OpenSSL 3 migration performed (out of scope; legacy environment preserved).

---

## 9. cURL Verification

- php_curl.dll imports libssh2.dll, LIBEAY32.dll, SSLEAY32.dll (no separate
  libcurl.dll; curl is statically linked).
- Runtime: `curl_version = 7.42.1`.
- HTTPS/TLS path resolves through SSLEAY32/LIBEAY32 as expected.

---

## 10. Final Validation

```
mysqli=YES   pdo_mysql=YES   gd=YES   openssl=YES
curl=YES     mbstring=YES    fileinfo=YES
ssl=OpenSSL 0.9.8zf 19 Mar 2015
curl=7.42.1
php=5.4.45
```

Health check (`scripts\health_check.cmd`):

```
[OK] Apache service  running        [OK] PHP stack     php 5.4.45, mysqli OK
[OK] MariaDB service running        [OK] PHP CLI       PHP 5.4.45
[OK] HTTP port       TCP 8000       [OK] Database login user 'root' can connect
[OK] DB port         TCP 3306       [OK] Disk / Memory / CPU
HEALTH STATUS : HEALTHY
```

Apache started cleanly after the fix: no PHP startup warnings in php-error.log.

---

## Conclusion

OZIRIS Server is **fully operational**. All 7 enabled PHP extensions — including
`php_openssl.dll` and `php_curl.dll` — load correctly under mod_php. The
original failure was a Windows DLL search-order issue (extension dependencies
not visible to httpd.exe), now fixed by placing the matching distribution DLLs
in `apache24\bin` and making `configure_php.cmd` reapply the fix automatically.
No architecture mismatches, correct VC9 runtime present, no replacement of
legacy libraries with arbitrary downloads.
