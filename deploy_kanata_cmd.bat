@echo off
setlocal

:: ============================================
:: Deploy the launcher, config, and binary
:: (bin\kanata.cmd, bin\kanata.kbd,
:: bin\kanata_windows_tty_winIOv2_x64.exe)
:: to the fixed per-user launch location, all
:: in one self-contained folder.
:: Run this after every "git pull" that touches
:: any of those, on each PC (host + remotes).
:: ============================================

set "HOTKEY_DIR=%~dp0"
set "HOTKEY_DIR=%HOTKEY_DIR:~0,-1%"
set "SRC_DIR=%HOTKEY_DIR%\bin"
set "DEST_DIR=%USERPROFILE%\bin"
set "BINARY_NAME=kanata_windows_tty_winIOv2_x64.exe"

if not exist "%SRC_DIR%\kanata.cmd" (
    echo [ERROR] Source not found: %SRC_DIR%\kanata.cmd
    pause
    exit /b 1
)

if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%"
)

copy /y "%SRC_DIR%\kanata.cmd" "%DEST_DIR%\kanata.cmd" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy launcher to: %DEST_DIR%\kanata.cmd
    pause
    exit /b 1
)
echo [SUCCESS] Deployed launcher: %DEST_DIR%\kanata.cmd

copy /y "%SRC_DIR%\kanata.kbd" "%DEST_DIR%\kanata.kbd" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy config to: %DEST_DIR%\kanata.kbd
    pause
    exit /b 1
)
echo [SUCCESS] Deployed config: %DEST_DIR%\kanata.kbd

if exist "%SRC_DIR%\%BINARY_NAME%" (
    copy /y "%SRC_DIR%\%BINARY_NAME%" "%DEST_DIR%\%BINARY_NAME%" >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy binary to: %DEST_DIR%\%BINARY_NAME%
        pause
        exit /b 1
    )
    echo [SUCCESS] Deployed binary: %DEST_DIR%\%BINARY_NAME%
) else (
    echo [WARNING] Binary not found in repo, skipped: %SRC_DIR%\%BINARY_NAME%
    if not exist "%DEST_DIR%\%BINARY_NAME%" (
        echo [ERROR] No binary at destination either. Place %BINARY_NAME% in %SRC_DIR% or %DEST_DIR% before running kanata.
    )
)

echo.
echo   Restart kanata.cmd for changes to take effect.
pause
