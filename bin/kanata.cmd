@echo off
set "SELF_DIR=%~dp0"
set "SELF_DIR=%SELF_DIR:~0,-1%"
set "CAPSPIDFILE=%TEMP%\kanata_capslock_watcher.pid"
start "" /min powershell -NoProfile -WindowStyle Hidden -Command "$PID | Out-File -FilePath '%CAPSPIDFILE%' -Encoding ascii; Add-Type -AssemblyName System.Windows.Forms; while ($true) { if ([System.Windows.Forms.Control]::IsKeyLocked('CapsLock')) { (New-Object -ComObject WScript.Shell).SendKeys('{CAPSLOCK}') }; Start-Sleep -Seconds 60 }"

powershell -NoProfile -Command "$logDir = Join-Path '%SELF_DIR%' 'logs'; if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }; Get-ChildItem -Path $logDir -Filter 'kanata_*.log' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } | Remove-Item -Force -ErrorAction SilentlyContinue; $logFile = Join-Path $logDir ('kanata_' + $env:COMPUTERNAME + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log'); Write-Host ('Logging to: ' + $logFile); & '%SELF_DIR%\kanata_windows_tty_winIOv2_x64.exe' --cfg '%SELF_DIR%\kanata.kbd' --debug --log-layer-changes %* 2>&1 | Tee-Object -FilePath $logFile"

if exist "%CAPSPIDFILE%" (
    for /f %%P in ('type "%CAPSPIDFILE%"') do taskkill /PID %%P /F >nul 2>&1
    del "%CAPSPIDFILE%" >nul 2>&1
)
