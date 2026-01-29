; ============================================
; Base Layer Hotkeys Module
; ============================================

; 캡스락 누를 때 플래그 초기화 및 레이어 활성화
; RDP 창 활성 시에는 호스트에서 후킹하지 않음
#HotIf !isRDP
CapsLock::
{
    global capsLockUsedWithOtherKey := false
    global LAYER_MOUSE

    ; 로깅: CapsLock 키 누름
    LogKeyEvent("CAPSLOCK_PRESS", "timeMs=" A_TickCount)
    LogKeyStateAnalysis("CapsLock 키 누름 감지")

    ; 캡스락 상태를 즉시 OFF로 설정
    SetCapsLockState "AlwaysOff"

    ; 레이어 활성화 (타이밍 추적 시작)
    ActivateLayer(LAYER_MOUSE)

    KeyWait "CapsLock"  ; 캡스락이 떼어질 때까지 대기

    ; 레이어 비활성화
    DeactivateLayer(LAYER_MOUSE)

    ; 로깅: CapsLock 키 해제 및 상태
    sendHangul := !capsLockUsedWithOtherKey
    usageType := capsLockUsedWithOtherKey ? "chord" : "solo"
    LogKeyEvent("CAPSLOCK_RELEASE", "usageType=" usageType " | capsLockUsedWithOtherKey=" capsLockUsedWithOtherKey " | sendHangul=" sendHangul " | timeMs=" A_TickCount)

    ; 다른 키와 함께 사용되지 않았을 때만 한영전환
    if (!capsLockUsedWithOtherKey)
    {
        LogKeyEvent("HANGUL_TOGGLE_SEND", "sending hangul toggle (vk15sc1F2) at " A_TickCount)
        SendInput "{vk15sc1F2}"
        LogKeyEvent("HANGUL_TOGGLE_COMPLETE", "hangul toggle sent at " A_TickCount)
    }

    ; 캡스락 상태를 다시 한번 확실히 OFF로 설정
    SetCapsLockState "AlwaysOff"
    return
}
#HotIf

; 스페이스 바 누를 때 플래그 초기화 및 레이어 활성화
; * 와일드카드 사용: Shift/Ctrl 등과 함께 눌러도 작동하고 다른 핫키에 전파
*Space::
{
    global spaceUsedWithOtherKey := false
    global LAYER_NAV
    global spaceLayerActive
    global spaceLayerQualified := false    ; Space 레이어 인정 상태 초기화
    global spaceOtherKeyPressed := false   ; 다른 키 눌림 상태 초기화
    global spaceFirstOtherKeyTime := 0     ; 다른 키 누른 시각 초기화

    ; 이미 Space 레이어가 활성화되어 있다면 중복 트리거 방지
    if (spaceLayerActive)
        return

    ; 로깅: Space 키 누름
    LogKeyEvent("SPACE_PRESS", "timeMs=" A_TickCount)
    LogKeyStateAnalysis("Space 키 누름 감지")

    ; 레이어 활성화 (타이밍 추적 시작)
    ActivateLayer(LAYER_NAV)

    ; 단독 홀드 인정 타이머 설정 (500ms 후에 spaceLayerQualified = true)
    SetTimer(SpaceSoloQualifyTimer, spaceMinHoldTime)

    return
}

; 스페이스 바를 뗄 때 레이어 비활성화 및 공백 입력
*Space up::
{
    global spaceUsedWithOtherKey
    global altTabMenuOpen
    global LAYER_NAV
    global spaceLayerQualified     ; Space 레이어 인정 상태 정리용
    global spaceOtherKeyPressed    ; 다른 키 눌림 상태 정리용
    global spaceFirstOtherKeyTime  ; 다른 키 누른 시각 정리용

    ; 단독 홀드 인정 타이머 중지
    SetTimer(SpaceSoloQualifyTimer, 0)

    ; 레이어 비활성화
    DeactivateLayer(LAYER_NAV)

    ; Alt+Tab 메뉴가 열려있으면 Alt 키를 떼어서 윈도우 전환
    if (altTabMenuOpen)
    {
        Send "{Alt up}"
        altTabMenuOpen := false
    }

    ; 공백 전송 여부 결정 (새로운 규칙 적용)
    ; - 매핑 실행됨: 공백 X
    ; - 매핑 실행 안 됨 & 다른 키 눌림: 공백 X
    ; - 매핑 실행 안 됨 & 아무 키도 안 눌림: 공백 O
    sendSpace := !spaceUsedWithOtherKey && !spaceOtherKeyPressed

    LogKeyEvent("SPACE_RELEASE", "spaceUsedWithOtherKey=" spaceUsedWithOtherKey " | spaceOtherKeyPressed=" spaceOtherKeyPressed " | spaceLayerQualified=" spaceLayerQualified " | sendSpace=" sendSpace " | timeMs=" A_TickCount)

    ; 규칙에 따라 공백 입력
    if (sendSpace)
    {
        Send " "
        LogKeyEvent("SPACE_SENT", "space character sent")
    }

    ; Space 키가 물리적으로 아직 눌려있는 경우 강제로 해제
    if GetKeyState("Space", "P")
    {
        Send "{Space up}"
        LogKeyEvent("SPACE_FORCE_RELEASE", "Space key was still physically pressed")
    }

    return
}

; ============================================
; 실제 Alt+Tab 키 감지 및 플래그 설정
; ============================================

; Alt+Tab 핫키 - altTabMenuOpen 플래그 설정
!Tab::
{
    global altTabMenuOpen

    ; Alt+Tab 메뉴가 열렸음을 표시
    altTabMenuOpen := true

    ; 원래 Alt+Tab 동작 전달
    Send "{Alt down}{Tab}"

    return
}

; Alt+Shift+Tab 핫키 - 역방향 전환
!+Tab::
{
    global altTabMenuOpen

    ; Alt+Tab 메뉴가 열렸음을 표시
    altTabMenuOpen := true

    ; 원래 Alt+Shift+Tab 동작 전달
    Send "{Alt down}{Shift down}{Tab}"

    return
}

; Alt 키가 떼어질 때 플래그 초기화
~Alt up::
{
    global altTabMenuOpen

    ; Alt+Tab 메뉴 닫기
    if (altTabMenuOpen)
    {
        altTabMenuOpen := false
    }

    return
}

; ============================================
; 긴급 레이어 리셋 핫키
; ============================================

; Ctrl + Alt + Shift + Esc: 모든 레이어를 강제로 리셋
^!+Esc::
{
    global altTabMenuOpen

    ; 모든 레이어 강제 초기화
    ForceResetAllLayers()

    ; 모든 키 상태 초기화
    ResetAllKeyStates(false)

    ; Alt+Tab 메뉴도 닫기
    if (altTabMenuOpen)
    {
        Send "{Alt up}"
        altTabMenuOpen := false
    }

    ; 캡스락 상태 확실히 OFF
    SetCapsLockState "AlwaysOff"

    ; 사용자에게 피드백 (선택사항 - 툴팁)
    ToolTip "레이어 리셋 완료"
    SetTimer(() => ToolTip(), -1000)  ; 1초 후 툴팁 제거

    return
}
