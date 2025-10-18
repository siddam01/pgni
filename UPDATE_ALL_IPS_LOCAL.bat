@echo off
setlocal enabledelayedexpansion

echo ================================================================
echo UPDATING ALL IP ADDRESSES
echo ================================================================
echo.
echo Old IP: 13.221.117.236
echo New IP: 54.227.101.30
echo.

set count=0

for /r %%f in (*.sh *.md) do (
    if not "%%~pf"=="%CD%\.git\" (
        findstr /C:"13.221.117.236" "%%f" >nul 2>&1
        if !errorlevel! equ 0 (
            powershell -Command "(Get-Content '%%f') -replace '13\.221\.117\.236', '54.227.101.30' | Set-Content '%%f'"
            echo Updated: %%~nxf
            set /a count+=1
        )
    )
)

echo.
echo ================================================================
echo Updated %count% files
echo ================================================================
pause

