@echo off
cd /d "%~dp0"

:: Neu co Run-VPN-Smart.ps1 thi goi an hoan toan (-WindowStyle Hidden)
if exist "%~dp0Run-VPN-Smart.ps1" (
    fsutil dirty query %systemdrive% >nul 2>&1
    if %errorLevel% neq 0 (
        powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%~dp0Run-VPN-Smart.ps1\"' -Verb RunAs -WindowStyle Hidden"
        exit /b
    )
    start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Run-VPN-Smart.ps1"
    exit /b
)

:: Fallback neu khong co file .ps1
if exist "VPN-Gate-Smart.exe" (
    start "" "VPN-Gate-Smart.exe"
) else (
    start "" "vpngate-smart.exe"
)