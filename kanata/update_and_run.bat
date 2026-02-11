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
set "SCRIPT_VERSION=1.9"
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
echo  Kanata Update and Run Script v%SCRIPT_VERSION%
echo ============================================
echo.

:: ============================================
:: 0. Self-update script
:: ============================================
:: Skip self-update if flag is set
if "%~1"=="--skip-self-update" goto :skip_self_update

echo [0/5] Checking script update...

set "SCRIPT_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/%SCRIPT_NAME%"
set "TEMP_SCRIPT=bin\%SCRIPT_NAME%.new"

:: Check bin directory for temp script
if not exist "bin" mkdir "bin"

:: Download latest script to temp (with cache bypass)
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%TEMP_SCRIPT%' -TimeoutSec 30 -UseBasicParsing -Headers @{'Cache-Control'='no-cache, no-store'; 'Pragma'='no-cache'} } catch { exit 1 }"

if not exist "%TEMP_SCRIPT%" (
    echo   [WARNING] Cannot download script. Continuing with current version.
    goto :skip_self_update
)

:: Check if downloaded script has the self-update marker (to avoid downgrade)
findstr /C:"[0/5] Checking script update" "%TEMP_SCRIPT%" >nul 2>&1
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

:: If script contents differ, only update when remote version is newer
set "SELFUPDATE_DECISION="
for /f "delims=" %%i in ('powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; function Get-Ver([string]$p){ $t=((Get-Content -LiteralPath $p -TotalCount 80 -ErrorAction SilentlyContinue) -join [Environment]::NewLine); $m=[regex]::Match($t,'SCRIPT_VERSION=([0-9.]+)'); if($m.Success){ return $m.Groups[1].Value }; $m=[regex]::Match($t,'Kanata Update and Run Script v([0-9.]+)'); if($m.Success){ return $m.Groups[1].Value }; return '0.0' }; $lv=Get-Ver '%~f0'; $rv=Get-Ver '%TEMP_SCRIPT%'; if([version]$rv -gt [version]$lv){ 'UPDATE' } else { 'SKIP' }"') do set "SELFUPDATE_DECISION=%%i"

if "%SELFUPDATE_DECISION%"=="SKIP" (
    echo   [INFO] Local script is newer or equal. Skipping self-update.
    del "%TEMP_SCRIPT%" 2>nul
    goto :skip_self_update
)

echo   [INFO] New script version found! Updating...

:: Create a temporary batch file to perform the update safely
:: This avoids modifying the currently running script
set "UPDATE_BAT=bin\kanata_update_%RANDOM%.bat"
echo @echo off > "%UPDATE_BAT%"
echo timeout /t 1 /nobreak ^>nul >> "%UPDATE_BAT%"
echo copy /y "%TEMP_SCRIPT%" "%~f0" ^>nul 2^>^&1 >> "%UPDATE_BAT%"
echo del "%TEMP_SCRIPT%" 2^>nul >> "%UPDATE_BAT%"
echo call "%~f0" --skip-self-update >> "%UPDATE_BAT%"
echo del "%%~f0" 2^>nul >> "%UPDATE_BAT%"

:: Start the update process and exit current instance
start "" /b cmd /c "%UPDATE_BAT%"
echo   [SUCCESS] Update initiated. Exiting current instance...
exit /b 0

:skip_self_update

:: ============================================
:: 1. Check CapsLock registry setting
:: ============================================
echo [1/5] Checking CapsLock registry...

set "CAPSLOCK_REG_PATH=bin\disable_capslock.reg"

:: Check if registry value is correctly set using PowerShell
for /f "delims=" %%i in ('powershell -NoProfile -Command "$expected = @(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x64,0x00,0x3a,0x00,0x00,0x00,0x00,0x00); $actual = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map' -ErrorAction SilentlyContinue).'Scancode Map'; if ($null -eq $actual) { 'NOT_SET' } elseif ($null -ne (Compare-Object $expected $actual)) { 'DIFFERENT' } else { 'OK' }"') do set "CAPSLOCK_STATUS=%%i"

if "%CAPSLOCK_STATUS%"=="OK" (
    echo   [INFO] CapsLock registry is already configured.
    goto :capslock_done
)

echo   [WARNING] CapsLock registry is not configured or different.
echo   Registry setting is required for Kanata to work properly.
echo.

:: Check bin directory
if not exist "bin" mkdir "bin"

:: Download registry file if not exists
set "REG_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/bin/disable_capslock.reg"
if not exist "%CAPSLOCK_REG_PATH%" (
    echo   Downloading: disable_capslock.reg
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%REG_URL%' -OutFile '%CAPSLOCK_REG_PATH%' -TimeoutSec 30 -UseBasicParsing -Headers @{'Cache-Control'='no-cache, no-store'; 'Pragma'='no-cache'} } catch { exit 1 }"
)

:: Check if registry file exists after download attempt
if not exist "%CAPSLOCK_REG_PATH%" (
    echo   [ERROR] Failed to download registry file.
    echo   Please check network connection and try again.
    pause
    exit /b 1
)

:: Check for administrator privileges
net session >nul 2>&1
if errorlevel 1 (
    echo   [INFO] Administrator privileges required to modify registry.
    echo   Requesting elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--skip-self-update'"
    exit /b 0
)

:: Apply registry setting
echo   Applying CapsLock registry setting...
reg import "%CAPSLOCK_REG_PATH%" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Failed to apply registry setting.
    pause
    exit /b 1
)
echo   [SUCCESS] Registry setting applied.
echo.

:: Ask for reboot
echo   ============================================
echo   REBOOT REQUIRED
echo   ============================================
echo   The registry change requires a system reboot
echo   to take effect.
echo.
set /p "REBOOT_CHOICE=   Reboot now? (Y/N): "
if /i "%REBOOT_CHOICE%"=="Y" (
    echo.
    echo   Rebooting in 5 seconds...
    shutdown /r /t 5
    exit /b 0
)
echo   [INFO] Please reboot manually later for changes to take effect.
echo.

:capslock_done

:: ============================================
:: 2. Check and update binary version
:: ============================================
echo [2/5] Checking binary version...

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
set "LATEST_VERSION="
set "DOWNLOAD_URL="
set "ZIP_NAME="
set "VERSION_TMP=bin\version_check_%RANDOM%.tmp"

:: Run PowerShell standalone and redirect output to temp file (avoids cmd.exe parenthesis parsing issue)
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{ $d=[char]124; $headers=@{'User-Agent'='kanata-update-script';'Accept'='application/vnd.github+json'}; $r=Invoke-RestMethod -Uri 'https://api.github.com/repos/%KANATA_REPO%/releases/latest' -Headers $headers -TimeoutSec 15 -ErrorAction Stop; $tag=$r.tag_name; $arch=if($env:PROCESSOR_ARCHITECTURE -eq 'ARM64'){'arm64'}else{'x64'}; $preferred='windows-binaries-'+$arch+'.zip'; $asset=$null; foreach($a in $r.assets){if($a.name -eq $preferred){$asset=$a;break}}; if(-not $asset){foreach($a in $r.assets){if($a.name -like 'windows-binaries-*.zip'){$asset=$a;break}}}; if(-not $asset){$tag+$d+$d}else{$tag+$d+$asset.browser_download_url+$d+$asset.name}}catch{$d=[char]124;'ERROR'+$d+$d}" > "%VERSION_TMP%" 2>nul

:: Read result from temp file (for /f with usebackq reads a FILE, not a command -- no parsing issues)
for /f "usebackq tokens=1-3 delims=|" %%a in ("%VERSION_TMP%") do (
    set "LATEST_VERSION=%%a"
    set "DOWNLOAD_URL=%%b"
    set "ZIP_NAME=%%c"
)
del "%VERSION_TMP%" 2>nul

if "%LATEST_VERSION%"=="ERROR" (
    echo   [WARNING] Cannot check latest version. Please check network connection.
    goto :update_config
)

if "%DOWNLOAD_URL%"=="" (
    echo   [WARNING] Latest release found: %LATEST_VERSION%, but cannot locate Windows binaries asset.
    echo   [WARNING] Please download manually from: https://github.com/%KANATA_REPO%/releases/latest
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
echo   New version found^! Downloading...

:: Create temp directory
set "TEMP_DIR=bin\kanata_update_%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul

:: Download ZIP file
set "ZIP_PATH=%TEMP_DIR%\%ZIP_NAME%"

echo   Downloading: %ZIP_NAME%
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_PATH%' -TimeoutSec 120 -UseBasicParsing } catch { exit 1 }"

if not exist "%ZIP_PATH%" (
    echo   [ERROR] Download failed^^!
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
:: 3. Update config and icons
:: ============================================
:update_config
echo.
echo [3/5] Updating config and icons...

:: Check icons directory
if not exist "icons" mkdir "icons"

:: Download config file
set "CONFIG_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/bin/kanata.kbd"
echo   Downloading: kanata.kbd
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG_PATH%' -TimeoutSec 30 -UseBasicParsing -Headers @{'Cache-Control'='no-cache, no-store'; 'Pragma'='no-cache'}; Write-Host '   [SUCCESS] kanata.kbd' } catch { Write-Host '   [WARNING] kanata.kbd download failed' }"

:: Download icon files
set "ICONS_BASE_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/icons"

echo   Downloading: base.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/base.ico' -OutFile '%ICONS_PATH%\base.ico' -TimeoutSec 30 -UseBasicParsing -Headers @{'Cache-Control'='no-cache, no-store'; 'Pragma'='no-cache'} } catch { }"

echo   Downloading: mouse.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/mouse.ico' -OutFile '%ICONS_PATH%\mouse.ico' -TimeoutSec 30 -UseBasicParsing -Headers @{'Cache-Control'='no-cache, no-store'; 'Pragma'='no-cache'} } catch { }"

echo   Downloading: nav.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/nav.ico' -OutFile '%ICONS_PATH%\nav.ico' -TimeoutSec 30 -UseBasicParsing -Headers @{'Cache-Control'='no-cache, no-store'; 'Pragma'='no-cache'} } catch { }"

echo   [DONE] Config update complete

:: ============================================
:: 4. Run Kanata
:: ============================================
:run_kanata
echo.
echo [4/5] Starting Kanata...

:: Terminate all existing Kanata processes and CapsLock monitor
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

:: Run Kanata (fully detached using VBS)
echo Set ws = CreateObject("WScript.Shell") > "bin\run_kanata.vbs"
echo ws.Run """%BINARY_PATH%"" --cfg ""%CONFIG_PATH%""", 0, False >> "bin\run_kanata.vbs"
wscript //nologo "bin\run_kanata.vbs"
del "bin\run_kanata.vbs" 2>nul

exit /b 0
