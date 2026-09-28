@echo off
set "SELF_DIR=%~dp0"
set "SELF_DIR=%SELF_DIR:~0,-1%"
set "CAPSPIDFILE=%TEMP%\kanata_capslock_watcher.pid"
set "FOCUSPIDFILE=%TEMP%\kanata_focus_watcher.pid"
set "CAPS_POLL_INTERVAL_MS=250"
set "FOCUS_POLL_INTERVAL_MS=250"
set "KANATA_TCP_PORT=7070"

rem PID file only remembers the latest watcher generation. If kanata.exe was
rem ever killed abruptly across multiple prior runs, several older watcher
rem generations can be orphaned with no PID recorded anywhere. Sweep by a
rem command-line marker so every leftover generation gets cleaned up, not
rem just the most recent one.
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and ($_.CommandLine -like '*Win32Focus*' -or $_.CommandLine -like '*IsKeyLocked*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

if exist "%CAPSPIDFILE%" del "%CAPSPIDFILE%" >nul 2>&1
if exist "%FOCUSPIDFILE%" del "%FOCUSPIDFILE%" >nul 2>&1

set "LOGDIR=%SELF_DIR%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%T"
set "LOGFILE=%LOGDIR%\kanata_%COMPUTERNAME%_%TS%.log"
echo Logging to: %LOGFILE%

powershell -NoProfile -Command "Get-ChildItem -Path '%LOGDIR%' -Filter 'kanata_*.log' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } | Remove-Item -Force -ErrorAction SilentlyContinue"

start "" /min powershell -NoProfile -WindowStyle Hidden -Command "$PID | Out-File -FilePath '%CAPSPIDFILE%' -Encoding ascii; Add-Type -AssemblyName System.Windows.Forms; $q = [char]34; $cs = 'using System; using System.Runtime.InteropServices; public class Win32Caps { [DllImport(' + $q + 'user32.dll' + $q + ')] public static extern IntPtr GetForegroundWindow(); [DllImport(' + $q + 'user32.dll' + $q + ')] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId); }'; Add-Type -TypeDefinition $cs; while ($true) { if ([System.Windows.Forms.Control]::IsKeyLocked('CapsLock')) { Start-Sleep -Milliseconds 1000; if ([System.Windows.Forms.Control]::IsKeyLocked('CapsLock')) { $hwnd = [Win32Caps]::GetForegroundWindow(); $procId = 0; [Win32Caps]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null; $fp = Get-Process -Id $procId -ErrorAction SilentlyContinue; $fname = if ($fp) { $fp.ProcessName } else { '' }; if ($fname -ne 'mstsc') { (New-Object -ComObject WScript.Shell).SendKeys('{CAPSLOCK}'); Add-Content -Path '%LOGFILE%' -Value ((Get-Date -Format 'HH:mm:ss.ffff') + ' [CapsWatcher] CapsLock lock state stayed on after debounce, sent correction SendKeys') } else { Add-Content -Path '%LOGFILE%' -Value ((Get-Date -Format 'HH:mm:ss.ffff') + ' [CapsWatcher] CapsLock stuck but mstsc has focus, deferring correction to avoid leaking a toggle into remote') } } }; Start-Sleep -Milliseconds %CAPS_POLL_INTERVAL_MS% }"

start "" /min powershell -NoProfile -WindowStyle Hidden -Command "$PID | Out-File -FilePath '%FOCUSPIDFILE%' -Encoding ascii; $q = [char]34; $cs = 'using System; using System.Runtime.InteropServices; public class Win32Focus { [DllImport(' + $q + 'user32.dll' + $q + ')] public static extern IntPtr GetForegroundWindow(); [DllImport(' + $q + 'user32.dll' + $q + ')] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId); }'; Add-Type -TypeDefinition $cs; $prev = ''; while ($true) { try { $hwnd = [Win32Focus]::GetForegroundWindow(); $procId = 0; [Win32Focus]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null; $p = Get-Process -Id $procId -ErrorAction SilentlyContinue; $name = if ($p) { $p.ProcessName } else { '' }; if ($name -eq 'mstsc' -and $prev -ne 'mstsc') { try { $client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', %KANATA_TCP_PORT%); $stream = $client.GetStream(); $payload = '{' + $q + 'ActOnFakeKey' + $q + ':{' + $q + 'name' + $q + ':' + $q + 'mrls-auto' + $q + ',' + $q + 'action' + $q + ':' + $q + 'Tap' + $q + '}}'; $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload); $stream.Write($bytes, 0, $bytes.Length); $stream.Flush(); Start-Sleep -Milliseconds 100; $buf = New-Object byte[] 4096; $drainGuard = 0; while ($stream.DataAvailable -and $drainGuard -lt 20) { $stream.Read($buf, 0, $buf.Length) | Out-Null; $drainGuard = $drainGuard + 1 }; $client.Close(); Add-Content -Path '%LOGFILE%' -Value ((Get-Date -Format 'HH:mm:ss.ffff') + ' [FocusWatcher] mstsc focus detected -> triggered mrls-auto') } catch { Add-Content -Path '%LOGFILE%' -Value ((Get-Date -Format 'HH:mm:ss.ffff') + ' [FocusWatcher] TCP send failed: ' + $_.Exception.Message) } }; if ($name) { $prev = $name } } catch {}; Start-Sleep -Milliseconds %FOCUS_POLL_INTERVAL_MS% }"

powershell -NoProfile -Command "& '%SELF_DIR%\kanata_windows_tty_winIOv2_x64.exe' --cfg '%SELF_DIR%\kanata.kbd' --port %KANATA_TCP_PORT% --debug --log-layer-changes %* 2>&1 | Tee-Object -FilePath '%LOGFILE%'"

if exist "%CAPSPIDFILE%" (
    for /f %%P in ('type "%CAPSPIDFILE%"') do taskkill /PID %%P /F >nul 2>&1
    del "%CAPSPIDFILE%" >nul 2>&1
)
if exist "%FOCUSPIDFILE%" (
    for /f %%P in ('type "%FOCUSPIDFILE%"') do taskkill /PID %%P /F >nul 2>&1
    del "%FOCUSPIDFILE%" >nul 2>&1
)
