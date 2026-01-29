; ============================================
; CapsLock Layer Hotkeys Module
; ============================================

; ============================================
; 캡스락이 눌린 상태에서의 키 매핑
; NOTE:
; 일부 환경(특히 CapsLock을 AlwaysOff로 강제하는 구성)에서는 GetKeyState("CapsLock","P") 판정이 불안정할 수 있음.
; 레이어 진입/이탈은 `base_hotkeys.ahk`에서 `capsLockLayerActive` 플래그로 관리하므로, 이를 기준으로 조건부 핫키를 활성화한다.
#HotIf capsLockLayerActive && !isRDP

; WASD -> 방향키 (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*w::SendKey("{Up}")
*a::SendKey("{Left}")
*s::SendKey("{Down}")
*d::SendKey("{Right}")


; ` -> 524287
`::
{
    global capsLockUsedWithOtherKey, LAYER_MOUSE

    ; 캡스락과 함께 사용되었음을 표시                 
    if GetKeyState("CapsLock", "P")
    {
        ; 레이어가 충분히 오래 눌렸는지 확인 (의도하지 않은 입력 방지)
        if (!IsLayerHeldLongEnough(LAYER_MOUSE))
            return
 
        capsLockUsedWithOtherKey := true
    }

    ; 로깅: CapsLock+` 단축키 실행 (텍스트 입력)
    LogKeyEvent("HOTKEY_EXEC", "CapsLock+` | mappedTo=SendText '524287'")

    SendText "524287"
}

; 1 -> 설정 파일에서 읽은 값
1::
{
    global capsLockUsedWithOtherKey, LAYER_MOUSE, capsLockText1

    ; 캡스락과 함께 사용되었음을 표시
    if GetKeyState("CapsLock", "P")
    {
        ; 레이어가 충분히 오래 눌렸는지 확인 (의도하지 않은 입력 방지)
        if (!IsLayerHeldLongEnough(LAYER_MOUSE))
            return

        capsLockUsedWithOtherKey := true
    }

    ; 설정 값이 없으면 무시
    if (capsLockText1 = "")
        return

    ; 로깅: CapsLock+1 단축키 실행 (설정 키 이름만 기록)
    LogKeyEvent("HOTKEY_EXEC", "CapsLock+1 | mappedTo=SendText <config:caps_1>")

    SendText capsLockText1
}

; 2 -> 설정 파일에서 읽은 값
2::
{
    global capsLockUsedWithOtherKey, LAYER_MOUSE, capsLockText2

    ; 캡스락과 함께 사용되었음을 표시
    if GetKeyState("CapsLock", "P")
    {
        ; 레이어가 충분히 오래 눌렸는지 확인 (의도하지 않은 입력 방지)
        if (!IsLayerHeldLongEnough(LAYER_MOUSE))
            return

        capsLockUsedWithOtherKey := true
    }

    ; 설정 값이 없으면 무시
    if (capsLockText2 = "")
        return

    SendText capsLockText2
}

; 3 -> 설정 파일에서 읽은 값
3::
{
    global capsLockUsedWithOtherKey, LAYER_MOUSE, capsLockText3

    ; 캡스락과 함께 사용되었음을 표시
    if GetKeyState("CapsLock", "P")
    {
        ; 레이어가 충분히 오래 눌렸는지 확인 (의도하지 않은 입력 방지)
        if (!IsLayerHeldLongEnough(LAYER_MOUSE))
            return

        capsLockUsedWithOtherKey := true
    }

    ; 설정 값이 없으면 무시
    if (capsLockText3 = "")
        return

    SendText capsLockText3
}

; q -> Home (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*q::SendKey("{Home}")

; r -> Mouse Wheel Up (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*r::SendKey("{WheelUp}")

; f -> Mouse Wheel Down (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*f::SendKey("{WheelDown}")                     

; t -> Page Up (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*t::SendKey("{PgUp}")
                       
; g -> Page Down (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*g::SendKey("{PgDn}")

; e -> End (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*e::SendKey("{End}")

; m -> 원격 데스크톱 창 최소화
m::
{
    global capsLockUsedWithOtherKey, altTabMenuOpen

    ; 캡스락과 함께 사용되었음을 표시
    if GetKeyState("CapsLock", "P")
        capsLockUsedWithOtherKey := true

    ; 원격 데스크톱 창 찾기 (mstsc.exe)
    if WinExist("ahk_class TscShellContainerClass")
    {
        WinMinimize

        ; 창 최소화 후 즉시 모든 키 상태 정리 (물리적 상태 포함)
        Sleep 50  ; 최소화가 완료될 시간 제공

        ; 다음 유효한 창으로 포커스 이동
        ActivateNextValidWindow()

        ResetAllKeyStates(altTabMenuOpen)

        return
    }
    ; 원격 데스크톱 창이 없으면 활성화된 창 최소화
    WinMinimize "A"

    ; 다음 유효한 창으로 포커스 이동
    ActivateNextValidWindow()
}

; Esc -> 모든 창 최소화
Esc::
{
    global capsLockUsedWithOtherKey

    ; 캡스락과 함께 사용되었음을 표시
    if GetKeyState("CapsLock", "P")
        capsLockUsedWithOtherKey := true

    Send "#d"
}

; ============================================
; 캡스락 + IJKL로 마우스 이동
; ============================================

; 캡스락 + I (위로)
*i::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true
    global lastVerticalKey := "i"
    UpdateMoveDirection()
    StartMouseMove()
    return
}

*i up::
{
    UpdateMoveDirection()
    return
}

; 캡스락 + K (아래로)
*k::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true
    global lastVerticalKey := "k"
    UpdateMoveDirection()
    StartMouseMove()
    return
}

*k up::
{
    UpdateMoveDirection()
    return
}

; 캡스락 + J (왼쪽으로)
*j::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true
    global lastHorizontalKey := "j"
    UpdateMoveDirection()
    StartMouseMove()
    return
}

*j up::
{
    UpdateMoveDirection()
    return
}

; 캡스락 + L (오른쪽으로)
*l::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true
    global lastHorizontalKey := "l"
    UpdateMoveDirection()
    StartMouseMove()
    return
}

*l up::
{
    UpdateMoveDirection()
    return
}

; 캡스락 + U (마우스 왼쪽 클릭)
*u::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true

    Sleep 50
    Click "left"
    Sleep 50
    return
}

; 캡스락 + O (마우스 오른쪽 클릭)
*o::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true

    Sleep 50
    Click "right"
    Sleep 50
    return
}

; 캡스락 + Y (마우스 휠 위로 - 스크롤 업)
*y::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true

    Sleep 10
    Click "WheelUp"
    return
}

; 캡스락 + H (마우스 휠 아래로 - 스크롤 다운)
*h::
{
    global capsLockUsedWithOtherKey
    capsLockUsedWithOtherKey := true

    Sleep 10
    Click "WheelDown"
    return
}

#HotIf
