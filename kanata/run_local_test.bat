@echo off
setlocal enabledelayedexpansion

:: ============================================
:: Kanata Local Config Test Runner
:: ============================================
:: - Uses local bin\kanata.kbd without downloading anything
:: - Stops existing Kanata processes
:: - Starts Kanata detached (tray/background)
:: ============================================

cd /d "%~dp0"

set "CONFIG_PATH=bin\kanata.kbd"
set "PREFERRED_BINARY=kanata_windows_gui_winIOv2_x64.exe"
set "BINARY_PATH=bin\%PREFERRED_BINARY%"
set "FOUND_BINARY="

echo ============================================
echo  Kanata Local Test Runner
echo ============================================
echo.

if not exist "%CONFIG_PATH%" (
    echo [ERROR] Config file not found: %CONFIG_PATH%
    echo.
    echo Copy or create local config first, then try again.
    pause
    exit /b 1
)

if not exist "%BINARY_PATH%" (
    for %%f in (
        "kanata_windows_gui_winIOv2_x64.exe"
        "kanata_windows_gui_winIOv2_cmd_allowed_x64.exe"
        "kanata_windows_gui_wintercept_x64.exe"
        "kanata_windows_gui_wintercept_cmd_allowed_x64.exe"
        "kanata_windows_tty_winIOv2_x64.exe"
        "kanata_windows_tty_winIOv2_cmd_allowed_x64.exe"
        "kanata_windows_tty_wintercept_x64.exe"
        "kanata_windows_tty_wintercept_cmd_allowed_x64.exe"
        "kanata.exe"
    ) do (
        if not defined FOUND_BINARY if exist "bin\%%~f" set "FOUND_BINARY=bin\%%~f"
    )
    if defined FOUND_BINARY (
        set "BINARY_PATH=!FOUND_BINARY!"
    )
)

if not exist "%BINARY_PATH%" (
    echo [ERROR] Kanata binary not found in .\bin
    echo.
    echo Run update_and_run.bat once to install binaries, then retry.
    pause
    exit /b 1
)

echo [1/3] Stopping existing Kanata processes...
taskkill /F /IM "kanata_windows_gui_winIOv2_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_gui_winIOv2_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_gui_wintercept_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_gui_wintercept_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_winIOv2_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_winIOv2_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_wintercept_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_wintercept_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata.exe" >nul 2>&1
timeout /t 1 /nobreak >nul
echo   Done

echo [2/3] Using local config: %CONFIG_PATH%
echo [3/3] Starting Kanata: %BINARY_PATH%
echo.

:: Fully detached start (no console window)
echo Set ws = CreateObject("WScript.Shell") > "bin\run_kanata_local.vbs"
echo ws.Run """%BINARY_PATH%"" --cfg ""%CONFIG_PATH%""", 0, False >> "bin\run_kanata_local.vbs"
wscript //nologo "bin\run_kanata_local.vbs"
del "bin\run_kanata_local.vbs" >nul 2>&1

echo ============================================
echo  Local test started.
echo  Edit bin\kanata.kbd and rerun this file.
echo ============================================

exit /b 0
