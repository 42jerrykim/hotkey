@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: Kanata 자동 업데이트 및 실행 스크립트
:: ============================================
:: - jtroo/kanata에서 최신 바이너리 다운로드
:: - 42jerrykim/hotkey에서 설정/아이콘 다운로드
:: - 버전 확인 후 새 버전만 업데이트
:: ============================================

:: 스크립트 디렉토리로 이동
cd /d "%~dp0"

:: 설정
set "BINARY_NAME=kanata_windows_gui_winIOv2_x64.exe"
set "BINARY_PATH=bin\%BINARY_NAME%"
set "VERSION_FILE=bin\version.txt"
set "CONFIG_PATH=config\settings.kbd"
set "ICONS_PATH=icons"

:: GitHub 저장소 설정
set "KANATA_REPO=jtroo/kanata"
set "CONFIG_REPO=42jerrykim/hotkey"
set "CONFIG_BRANCH=main"

echo ============================================
echo  Kanata 업데이트 및 실행 스크립트
echo ============================================
echo.

:: ============================================
:: 1. 바이너리 버전 확인 및 업데이트
:: ============================================
echo [1/3] 바이너리 버전 확인 중...

:: 현재 버전 읽기
set "CURRENT_VERSION="
if exist "%VERSION_FILE%" (
    set /p CURRENT_VERSION=<"%VERSION_FILE%"
    echo   현재 버전: !CURRENT_VERSION!
) else (
    echo   현재 버전: 설치되지 않음
)

:: GitHub API로 최신 버전 확인
echo   최신 버전 확인 중...
for /f "delims=" %%i in ('powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/%KANATA_REPO%/releases/latest' -TimeoutSec 10; $r.tag_name } catch { Write-Host 'ERROR' }"') do set "LATEST_VERSION=%%i"

if "%LATEST_VERSION%"=="ERROR" (
    echo   [경고] 최신 버전을 확인할 수 없습니다. 네트워크를 확인하세요.
    goto :update_config
)

echo   최신 버전: %LATEST_VERSION%

:: 버전 비교
if "%CURRENT_VERSION%"=="%LATEST_VERSION%" (
    echo   [정보] 이미 최신 버전입니다.
    goto :update_config
)

:: 새 버전 다운로드
echo.
echo   새 버전 발견! 다운로드 중...

:: 임시 디렉토리 생성
set "TEMP_DIR=%TEMP%\kanata_update_%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul

:: ZIP 파일 다운로드
set "ZIP_NAME=kanata-windows-binaries-x64-%LATEST_VERSION%.zip"
set "DOWNLOAD_URL=https://github.com/%KANATA_REPO%/releases/download/%LATEST_VERSION%/%ZIP_NAME%"
set "ZIP_PATH=%TEMP_DIR%\%ZIP_NAME%"

echo   다운로드: %ZIP_NAME%
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_PATH%' -TimeoutSec 120"

if not exist "%ZIP_PATH%" (
    echo   [오류] 다운로드 실패!
    rmdir /s /q "%TEMP_DIR%" 2>nul
    goto :update_config
)

:: ZIP 압축 해제
echo   압축 해제 중...
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%TEMP_DIR%\extracted' -Force"

:: bin 디렉토리 확인
if not exist "bin" mkdir "bin"

:: 바이너리 찾기 (ZIP 내부 구조가 다를 수 있음)
set "EXTRACTED_BINARY="
for /r "%TEMP_DIR%\extracted" %%f in (%BINARY_NAME%) do (
    set "EXTRACTED_BINARY=%%f"
)

if defined EXTRACTED_BINARY (
    if exist "!EXTRACTED_BINARY!" (
        :: 기존 바이너리 백업
        if exist "%BINARY_PATH%" (
            move /y "%BINARY_PATH%" "%BINARY_PATH%.bak" >nul 2>&1
        )
        
        :: 새 바이너리 복사
        copy /y "!EXTRACTED_BINARY!" "%BINARY_PATH%" >nul
        echo   복사 완료: %BINARY_NAME%
        
        :: passthru DLL도 찾아서 복사
        for /r "%TEMP_DIR%\extracted" %%f in (kanata_passthru_x64.dll) do (
            copy /y "%%f" "bin\kanata_passthru_x64.dll" >nul 2>&1
        )
        
        :: 버전 파일 업데이트
        echo %LATEST_VERSION%>"%VERSION_FILE%"
        
        echo   [성공] 바이너리 업데이트 완료: %LATEST_VERSION%
        
        :: 백업 파일 삭제
        del "%BINARY_PATH%.bak" 2>nul
    ) else (
        echo   [오류] 바이너리 파일을 찾았으나 복사할 수 없습니다.
    )
) else (
    echo   [오류] 압축 파일에서 바이너리를 찾을 수 없습니다.
    echo   압축 해제 위치: %TEMP_DIR%\extracted
    dir /s /b "%TEMP_DIR%\extracted\*.exe" 2>nul
)

:: 임시 디렉토리 정리
rmdir /s /q "%TEMP_DIR%" 2>nul

:: ============================================
:: 2. 설정 및 아이콘 업데이트
:: ============================================
:update_config
echo.
echo [2/3] 설정 및 아이콘 업데이트 중...

:: config 디렉토리 확인
if not exist "config" mkdir "config"
if not exist "icons" mkdir "icons"

:: 설정 파일 다운로드
set "CONFIG_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/config/settings.kbd"
echo   다운로드: settings.kbd
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%CONFIG_URL%' -OutFile '%CONFIG_PATH%' -TimeoutSec 30; Write-Host '   [성공] settings.kbd' } catch { Write-Host '   [경고] settings.kbd 다운로드 실패' }"

:: 아이콘 파일 다운로드
set "ICONS_BASE_URL=https://raw.githubusercontent.com/%CONFIG_REPO%/%CONFIG_BRANCH%/kanata/icons"

echo   다운로드: base.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/base.ico' -OutFile '%ICONS_PATH%\base.ico' -TimeoutSec 30 } catch { }"

echo   다운로드: mouse.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/mouse.ico' -OutFile '%ICONS_PATH%\mouse.ico' -TimeoutSec 30 } catch { }"

echo   다운로드: nav.ico
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%ICONS_BASE_URL%/nav.ico' -OutFile '%ICONS_PATH%\nav.ico' -TimeoutSec 30 } catch { }"

echo   [완료] 설정 업데이트 완료

:: ============================================
:: 3. Kanata 실행
:: ============================================
:run_kanata
echo.
echo [3/3] Kanata 실행 중...

:: 기존 Kanata 프로세스 모두 종료
echo   기존 Kanata 프로세스 확인 중...
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
echo   완료

if not exist "%BINARY_PATH%" (
    echo   [오류] Kanata 바이너리가 없습니다: %BINARY_PATH%
    echo   네트워크 연결을 확인하고 다시 시도하세요.
    pause
    exit /b 1
)

if not exist "%CONFIG_PATH%" (
    echo   [오류] 설정 파일이 없습니다: %CONFIG_PATH%
    pause
    exit /b 1
)

echo   실행: %BINARY_NAME%
echo   설정: %CONFIG_PATH%
echo.
echo ============================================
echo  Kanata가 시스템 트레이에서 실행됩니다.
echo  종료하려면 트레이 아이콘을 우클릭하세요.
echo ============================================

:: Kanata 실행 (GUI 모드이므로 start 사용)
start "" "%BINARY_PATH%" --cfg "%CONFIG_PATH%"

exit /b 0
