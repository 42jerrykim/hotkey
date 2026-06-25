@echo off
setlocal

set "HOTKEY_DIR=C:\Jerry\Util\Hotkey"

:: Check if already in PATH
echo %PATH% | findstr /i /c:"%HOTKEY_DIR%" >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Already in PATH: %HOTKEY_DIR%
    goto :done
)

:: Add to user PATH via PowerShell
powershell -NoProfile -Command ^
  "$cur = [Environment]::GetEnvironmentVariable('PATH','User');" ^
  "[Environment]::SetEnvironmentVariable('PATH', $cur + ';%HOTKEY_DIR%', 'User');" ^
  "Write-Host '[SUCCESS] Added to PATH: %HOTKEY_DIR%'"

:done
echo.
echo   Open a new cmd window to use:
echo     kanata-debug
echo     update_and_run
echo.
pause
