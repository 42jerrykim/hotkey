; ============================================
; Window Focus Monitoring and Reset Module
; ============================================

; Alt+Tab 메뉴가 열려있는지 추적
global altTabMenuOpen := false

; 원격 데스크톱 포커스 모니터링 변수
global lastActiveWindow := 0
global rdpWindowClass := "ahk_class TscShellContainerClass"

; 원격 데스크톱 환경 감지 플래그
global isRDP := false

; 마지막 d 키 입력 시간 (디바운싱용)
global lastDKeyTime := 0

; 다음 유효한 창으로 포커스 이동하는 함수
ActivateNextValidWindow()
{
    ; 모든 창 목록 가져오기
    windows := WinGetList()

    ; 각 창을 확인하여 첫 번째 유효한 창 찾기
    for hwnd in windows
    {
        ; 창이 최소화되지 않았고 표시 가능한 창인지 확인
        if !WinGetMinMax("ahk_id " hwnd) && WinExist("ahk_id " hwnd)
        {
            ; 제목이 비어있지 않은 창만 활성화
            title := WinGetTitle("ahk_id " hwnd)
            if (title != "")
            {
                ; 원격 데스크톱 창이 아닌 경우에만 활성화
                if !WinExist("ahk_id " hwnd " ahk_class TscShellContainerClass")
                {
                    WinActivate "ahk_id " hwnd
                    Sleep 50  ; 포커스 전환이 완료될 시간 제공
                    return
                }
            }
        }
    }
}

; 모든 키 상태를 강제로 초기화하는 함수
ResetAllKeyStates(preserveAltForAltTab := false)
{
    global capsLockUsedWithOtherKey, spaceUsedWithOtherKey, altTabMenuOpen
    global lastVerticalKey, lastHorizontalKey, isMouseMoving
    global spaceLayerQualified, spaceOtherKeyPressed, spaceFirstOtherKeyTime

    ; 플래그 초기화
    capsLockUsedWithOtherKey := false
    ; spaceUsedWithOtherKey := false
    spaceLayerQualified := false
    spaceOtherKeyPressed := false
    spaceFirstOtherKeyTime := 0
    lastVerticalKey := ""
    lastHorizontalKey := ""

    ; 레이어 상태 강제 초기화
    ForceResetAllLayers()

    ; 마우스 이동 중지
    if (isMouseMoving)
        StopMouseMove()

    ; 캡스락 상태 강제 OFF
    SetCapsLockState "AlwaysOff"

    ; 물리적으로 눌려있는 상태의 키들을 강제로 해제
    ; CapsLock 물리 상태 확인 및 해제
    if GetKeyState("CapsLock", "P")
        Send "{CapsLock up}"

    ; Space 물리 상태 확인 및 해제
    if GetKeyState("Space", "P")
        Send "{Space up}"

    ; 수식어 키들 물리 상태 확인 및 해제
    if GetKeyState("Ctrl", "P")
        Send "{Ctrl up}"

    if GetKeyState("Shift", "P")
        Send "{Shift up}"

    if GetKeyState("LWin", "P")
        Send "{LWin up}"

    if GetKeyState("RWin", "P")
        Send "{RWin up}"

    ; Alt 키 처리 (Alt+Tab 메뉴 상태에 따라)
    if (!preserveAltForAltTab || !altTabMenuOpen)
    {
        if GetKeyState("Alt", "P")
            Send "{Alt up}"
        altTabMenuOpen := false
    }

    ; 키 해제가 처리될 시간 제공
    Sleep 100
}

; 포커스 변경 감지 및 키 상태 초기화
CheckWindowFocus()
{
    global lastActiveWindow, rdpWindowClass
    global isRDP, altTabMenuOpen
    global capsLockLayerActive, spaceLayerActive
    global LAYER_MOUSE, LAYER_NAV

    currentWindow := WinExist("A")

    ; 원격 데스크톱 활성 상태 감지
    isRDP := WinActive(rdpWindowClass)

    ; 레이어 상태 검증 - 레이어 키가 물리적으로 눌려있지 않으면 레이어 비활성화
    ; NOTE: CapsLock은 AlwaysOff로 강제하는 구성에서 GetKeyState("CapsLock","P") 판정이 불안정할 수 있어
    ; 여기서 물리 상태 기반 자동 비활성화를 하지 않는다. (CapsLock 핫키의 KeyWait/릴리즈 및 포커스 변경 시 Reset이 정리함)

    if (spaceLayerActive && !GetKeyState("Space", "P"))
    {
        DeactivateLayer(LAYER_NAV)
    }

    ; 활성 윈도우가 변경되었을 때
    if (currentWindow != lastActiveWindow)
    {
        ; 원격 데스크톱으로 포커스가 이동한 경우
        if WinExist(rdpWindowClass) && WinActive(rdpWindowClass)
        {
            ; 모든 키 상태 초기화 (Alt+Tab 메뉴 고려)
            ResetAllKeyStates(altTabMenuOpen)

            ; RDP 활성 시 CapsLock 동기화 전송은 생략 (원격 스크립트와 충돌 방지)
        }
        else
        {
            ; 원격 데스크톱에서 벗어난 경우 (최소화 포함)
            ; 모든 키 상태 초기화 (Alt+Tab 메뉴 고려)
            ResetAllKeyStates(altTabMenuOpen)
        }

        lastActiveWindow := currentWindow
    }
}
