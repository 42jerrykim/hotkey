@echo off
setlocal enabledelayedexpansion

:: ============================================
:: Kanata Auto Update and Run Script
:: ============================================
:: - Self-update this script from GitHub
:: - Download latest binary from jtroo/kanata
:: - Download config/icons from 42jerrykim/hotkey
:: - Check version and update only if new version
:: ============================================

:: Move to script directory
cd /d "%~dp0"

:: Settings
set "SCRIPT_NAME=update_and_run.bat"
set "BINARY_NAME=kanata_windows_gui_winIOv2_x64.exe"
set "BINARY_PATH=bin\%BINARY_NAME%"
set "VERSION_FILE=bin\version.txt"
set "CONFIG_PATH=bin\kanata.kbd"
set "ICONS_PATH=icons"

:: GitHub repository settings
set "KANATA_REPO=jtroo/kanata"
set "CONFIG_REPO=42jerrykim/hotkey"
set "CONFIG_BRANCH=main"

echo ============================================
echo  Kanata Update and Run Script
echo ============================================
echo.

:: ============================================
:: 0. Self-update script
:: ============================================
:: Skip self-update if flag is set
if "%~1"=="--skip-self-update" goto :skip_self_update

echo [0/4] Checking script update...

set "SCRIPT_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/%SCRIPT_NAME%"
set "TEMP_SCRIPT=%TEMP%\%SCRIPT_NAME%.new"

:: Download latest script to temp
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%TEMP_SCRIPT%' -TimeoutSec 30 } catch { exit 1 }"

if not exist "%TEMP_SCRIPT%" (
    echo   [WARNING] Cannot download script. Continuing with current version.
    goto :skip_self_update
)

:: Check if downloaded script has the self-update marker (to avoid downgrade)
findstr /C:"[0/4] Checking script update" "%TEMP_SCRIPT%" >nul 2>&1
if errorlevel 1 (
    echo   [INFO] Remote script is older version. Skipping update.
    del "%TEMP_SCRIPT%" 2>nul
    goto :skip_self_update
)

:: Compare files using hash
for /f "delims=" %%i in ('powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; $h1=(Get-FileHash -LiteralPath '%~f0' -Algorithm MD5).Hash; $h2=(Get-FileHash -LiteralPath '%TEMP_SCRIPT%' -Algorithm MD5).Hash; if($h1 -eq $h2){'SAME'}else{'DIFFERENT'}"') do set "HASH_RESULT=%%i"

if "%HASH_RESULT%"=="SAME" (
    echo   [INFO] Script is up to date.
    del "%TEMP_SCRIPT%" 2>nul
    goto :skip_self_update
)

echo   [INFO] New script version found! Updating...

:: Copy new script and restart
copy /y "%TEMP_SCRIPT%" "%~f0" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Failed to update script.
    del "%TEMP_SCRIPT%" 2>nul
    goto :skip_self_update
)
del "%TEMP_SCRIPT%" 2>nul

echo   [SUCCESS] Script updated. Restarting...
echo.

:: Restart with skip flag to prevent infinite loop
call "%~f0" --skip-self-update
exit /b %errorlevel%

:skip_self_update

:: ============================================
:: 1. Check and update binary version
:: ============================================
echo [1/4] Checking binary version...

:: Read current version
set "CURRENT_VERSION="
if exist "%VERSION_FILE%" (
    set /p CURRENT_VERSION=<"%VERSION_FILE%"
    echo   Current version: !CURRENT_VERSION!
) else (
    echo   Current version: Not installed
)

:: Check latest version via GitHub API
echo   Checking latest version...
for /f "delims=" %%i in ('powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/%KANATA_REPO%/releases/latest' -TimeoutSec 10; $r.tag_name } catch { Write-Host 'ERROR' }"') do set "LATEST_VERSION=%%i"

if "%LATEST_VERSION%"=="ERROR" (
    echo   [WARNING] Cannot check latest version. Please check network connection.
    goto :update_config
)

echo   Latest version: %LATEST_VERSION%

:: Compare versions
if "%CURRENT_VERSION%"=="%LATEST_VERSION%" (
    echo   [INFO] Already up to date.
    goto :update_config
)

:: Download new version
echo.
echo   New version found! Downloading...

:: Create temp directory
set "TEMP_DIR=%TEMP%\kanata_update_%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul

:: Download ZIP file
set "ZIP_NAME=kanata-windows-binaries-x64-%LATEST_VERSION%.zip"
set "DOWNLOAD_URL=https://github.com/%KANATA_REPO%/releases/download/%LATEST_VERSION%/%ZIP_NAME%"
set "ZIP_PATH=%TEMP_DIR%\%ZIP_NAME%"

echo   Downloading: %ZIP_NAME%
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_PATH%' -TimeoutSec 120"

if not exist "%ZIP_PATH%" (
    echo   [ERROR] Download failed!
    rmdir /s /q "%TEMP_DIR%" 2>nul
    goto :update_config
)

:: Extract ZIP
echo   Extracting...
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%TEMP_DIR%\extracted' -Force"

:: Check bin directory
if not exist "bin" mkdir "bin"

:: Find binary (ZIP internal structure may vary)
set "EXTRACTED_BINARY="
for /r "%TEMP_DIR%\extracted" %%f in (%BINARY_NAME%) do (
    set "EXTRACTED_BINARY=%%f"
)

if defined EXTRACTED_BINARY (
    if exist "!EXTRACTED_BINARY!" (
        :: Backup existing binary
        if exist "%BINARY_PATH%" (
            move /y "%BINARY_PATH%" "%BINARY_PATH%.bak" >nul 2>&1
        )
        
        :: Copy new binary
        copy /y "!EXTRACTED_BINARY!" "%BINARY_PATH%" >nul
        echo   Copy complete: %BINARY_NAME%
        
        :: Find and copy passthru DLL
        for /r "%TEMP_DIR%\extracted" %%f in (kanata_passthru_x64.dll) do (
            copy /y "%%f" "bin\kanata_passthru_x64.dll" >nul 2>&1
        )
        
        :: Update version file
        echo %LATEST_VERSION%>"%VERSION_FILE%"
        
        echo   [SUCCESS] Binary update complete: %LATEST_VERSION%
        
        :: Delete backup file
        del "%BINARY_PATH%.bak" 2>nul
    ) else (
        echo   [ERROR] Found binary but cannot copy.
    )
) else (
    echo   [ERROR] Cannot find binary in archive.
    echo   Extract location: %TEMP_DIR%\extracted
    dir /s /b "%TEMP_DIR%\extracted\*.exe" 2>nul
)

:: Clean up temp directory
rmdir /s /q "%TEMP_DIR%" 2>nul

:: ============================================
:: 2. Update config and icons
:: ============================================
:update_config
echo.
echo [2/4] Updating config and icons...

:: Check icons directory
if not exist "icons" mkdir "icons"

:: Download config file
set "CONFIG_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/bin/kanata.kbd"
echo   Downloading: kanata.kbd
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG_PATH%' -TimeoutSec 30; Write-Host '   [SUCCESS] kanata.kbd' } catch { Write-Host '   [WARNING] kanata.kbd download failed' }"

:: Download icon files
set "ICONS_BASE_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/icons"

echo   Downloading: base.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/base.ico' -OutFile '%ICONS_PATH%\base.ico' -TimeoutSec 30 } catch { }"

echo   Downloading: mouse.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/mouse.ico' -OutFile '%ICONS_PATH%\mouse.ico' -TimeoutSec 30 } catch { }"

echo   Downloading: nav.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/nav.ico' -OutFile '%ICONS_PATH%\nav.ico' -TimeoutSec 30 } catch { }"

echo   [DONE] Config update complete

:: ============================================
:: 3. Run Kanata
:: ============================================
:run_kanata
echo.
echo [3/4] Starting Kanata...

:: Terminate all existing Kanata processes
echo   Checking existing Kanata processes...
taskkill /F /IM "kanata_windows_gui_winIOv2_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_gui_winIOv2_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_gui_wintercept_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_gui_wintercept_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_winIOv2_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_winIOv2_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_wintercept_x64.exe" >nul 2>&1
taskkill /F /IM "kanata_windows_tty_wintercept_cmd_allowed_x64.exe" >nul 2>&1
taskkill /F /IM "kanata.exe" >nul 2>&1
timeout /t 2 /nobreak >nul
echo   Done

if not exist "%BINARY_PATH%" (
    echo   [ERROR] Kanata binary not found: %BINARY_PATH%
    echo   Please check network connection and try again.
    pause
    exit /b 1
)

if not exist "%CONFIG_PATH%" (
    echo   [ERROR] Config file not found: %CONFIG_PATH%
    pause
    exit /b 1
)

echo   Running: %BINARY_NAME%
echo   Config: %CONFIG_PATH%
echo.
echo ============================================
echo  Kanata is running in system tray.
echo  Right-click tray icon to exit.
echo ============================================

:: Turn off CapsLock if it's on (prevents stuck uppercase)
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.Control]::IsKeyLocked('CapsLock')) { $wsh = New-Object -ComObject WScript.Shell; $wsh.SendKeys('{CAPSLOCK}') }"

:: Run Kanata (detached process)
powershell -NoProfile -Command "Start-Process -FilePath '%BINARY_PATH%' -ArgumentList '--cfg', '%CONFIG_PATH%' -WindowStyle Hidden"

exit /b 0
