@echo off
setlocal

:: ============================================
:: Deploy bin\kanata.cmd (repo-managed launcher)
:: to the fixed per-user launch location.
:: Run this after every "git pull" that touches
:: bin\kanata.cmd, on each PC (host + remotes).
:: ============================================

set "HOTKEY_DIR=%~dp0"
set "HOTKEY_DIR=%HOTKEY_DIR:~0,-1%"
set "SRC=%HOTKEY_DIR%\bin\kanata.cmd"
set "DEST_DIR=%USERPROFILE%\bin"
set "DEST=%DEST_DIR%\kanata.cmd"

if not exist "%SRC%" (
    echo [ERROR] Source not found: %SRC%
    pause
    exit /b 1
)

if not exist "%DEST_DIR%" (
    mkdir "%DEST_DIR%"
)

copy /y "%SRC%" "%DEST%" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy launcher to: %DEST%
    pause
    exit /b 1
)

echo [SUCCESS] Deployed launcher: %DEST%
echo   Restart kanata.cmd for the change to take effect.
pause
