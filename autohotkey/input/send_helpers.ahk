; ============================================
; Input Sending Helpers Module
; ============================================

; 캡스락이 다른 키와 함께 사용되었는지 추적
global capsLockUsedWithOtherKey := false

; 스페이스 바가 다른 키와 함께 사용되었는지 추적
global spaceUsedWithOtherKey := false

; 수식어 키와 함께 키를 전송하는 함수
SendKey(key)
{
    global capsLockUsedWithOtherKey, spaceUsedWithOtherKey

    ; 캡스락과 함께 사용되었음을 표시
    if GetKeyState("CapsLock", "P")
        capsLockUsedWithOtherKey := true

    ; 스페이스 바와 함께 사용되었음을 표시
    if GetKeyState("Space", "P")
        spaceUsedWithOtherKey := true

    modifiers := ""
    if GetKeyState("Shift", "P")
        modifiers .= "+"
    if GetKeyState("Ctrl", "P")
        modifiers .= "^"
    if GetKeyState("Alt", "P") && !GetKeyState("LAlt", "P")  ; 오른쪽 Alt만 (한영키 제외)
        modifiers .= "!"

    finalKey := modifiers . key
    
    ; 상세 로깅: 전송 전 상태
    LogKeyEvent("SEND_KEY_DETAIL", "input=" A_ThisHotkey " | modifiers=" modifiers 
        " | key=" key " | finalKey=" finalKey " | timeMs=" A_TickCount)
    
    ; 키 상태 분석 로깅
    LogKeyStateAnalysis("SendKey 실행: " A_ThisHotkey)

    Send finalKey
    
    ; 전송 후 상세 로깅
    LogKeyEvent("SEND_KEY_COMPLETE", "input=" A_ThisHotkey " | sent=" finalKey)
}

; 스페이스 바와 함께 사용되며 Ctrl을 강제로 추가하는 함수
SendKeyWithCtrl(key)
{
    global spaceUsedWithOtherKey

    ; 스페이스 바와 함께 사용되었음을 표시
    spaceUsedWithOtherKey := true

    ; 단일 알파벳 키는 소문자로 변환하여 Shift 자동 추가 방지
    if (StrLen(key) == 1 && RegExMatch(key, "^[A-Za-z]$"))
        key := StrLower(key)

    modifiers := "^"  ; Ctrl 키 추가
    if GetKeyState("Shift", "P")
        modifiers .= "+"
    if GetKeyState("Alt", "P") && !GetKeyState("LAlt", "P")  ; 오른쪽 Alt만 (한영키 제외)
        modifiers .= "!"

    finalKey := modifiers . key
    
    ; 상세 로깅: Ctrl 추가 정보
    LogKeyEvent("SEND_KEY_WITH_CTRL_DETAIL", "input=" A_ThisHotkey " | modifiers=" modifiers 
        " | key=" key " | finalKey=" finalKey " | timeMs=" A_TickCount)
    
    ; 키 상태 분석
    LogKeyStateAnalysis("SendKeyWithCtrl 실행: " A_ThisHotkey)

    Send finalKey
    
    ; 전송 후 상세 로깅
    LogKeyEvent("SEND_KEY_WITH_CTRL_COMPLETE", "input=" A_ThisHotkey " | sent=" finalKey)
}
