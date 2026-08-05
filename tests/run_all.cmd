@echo off
rem ==========================================================
rem  run_all.cmd - runs the full test suite.
rem  Exit: 0 = all passed, 2 = skips only, 1 = failures.
rem ==========================================================
setlocal EnableDelayedExpansion
set "FAILED=0"
set "SKIPPED=0"

for %%t in (test_config test_apache test_php test_mariadb test_phpmyadmin test_admin test_firewall test_backup test_restore test_health) do (
    echo.
    echo ===== %%t =====
    call "%~dp0%%t.cmd"
    set "TRC=!errorlevel!"
    if "!TRC!"=="2" (
        set /a SKIPPED+=1
        echo     SKIPPED
    ) else (
        if "!TRC!"=="0" (
            echo     PASSED
        ) else (
            set /a FAILED+=1
            echo     FAILED
        )
    )
)

echo.
echo ============================
if not "!FAILED!"=="0" goto :report_fail
if not "!SKIPPED!"=="0" goto :report_skip
echo  Result: ALL PASSED
echo ============================
exit /b 0

:report_fail
echo  Result: FAILED - !FAILED! test(s) failed
echo ============================
exit /b 1

:report_skip
echo  Result: PASSED - !SKIPPED! test(s) skipped ^(not installed^)
echo ============================
exit /b 2
