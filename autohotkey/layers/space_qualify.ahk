; ============================================
; Space Layer Qualification Module
; ============================================

; Space 레이어 500ms 필터 관련 상태
global spaceLayerQualified := false    ; Space 레이어가 500ms 규칙을 만족해 인정됐는지
global spaceOtherKeyPressed := false   ; Space를 누른 상태에서 수식키 제외 다른 키가 눌렸는지
global spaceFirstOtherKeyTime := 0     ; 다른 키가 처음 눌린 시각 (합산 홀드 계산용)

; Space 레이어 인정 시각 계산 (합산 홀드 조건 기반)
CalculateSpaceQualifyTime()
{
    global spaceActivationTime, spaceFirstOtherKeyTime, spaceMinHoldTime

    ; Space 홀드 시간 계산
    spaceHoldTime := A_TickCount - spaceActivationTime

    ; 다른 키가 눌렸는지 확인
    if (spaceFirstOtherKeyTime = 0)
    {
        ; 다른 키가 눌리지 않은 경우: Space 단독 500ms 조건
        qualifyAt := spaceActivationTime + spaceMinHoldTime
    }
    else
    {
        ; 다른 키가 눌린 경우: 합산 홀드 조건
        ; (spaceHoldTime + otherKeyHoldTime) >= 500ms
        ; otherKeyHoldTime = 현재시간 - spaceFirstOtherKeyTime
        ; 따라서: spaceHoldTime + (현재시간 - spaceFirstOtherKeyTime) >= 500ms
        ; 현재시간 >= spaceFirstOtherKeyTime + 500ms - spaceHoldTime
        ; 현재시간 >= spaceFirstOtherKeyTime + 500ms - (현재시간 - spaceActivationTime)
        ; 현재시간 >= spaceFirstOtherKeyTime + 500ms - 현재시간 + spaceActivationTime
        ; 2*현재시간 >= spaceFirstOtherKeyTime + 500ms + spaceActivationTime
        ; 현재시간 >= (spaceFirstOtherKeyTime + 500ms + spaceActivationTime) / 2

        qualifyAt := Ceil((spaceFirstOtherKeyTime + spaceMinHoldTime + spaceActivationTime) / 2)
    }

    return qualifyAt
}

; Space 레이어 키 핸들러 (지연 실행 및 패스스루 처리)
HandleSpaceLayerKey(keyName, action)
{
    global spaceLayerQualified, spaceOtherKeyPressed, spaceFirstOtherKeyTime
    global spaceUsedWithOtherKey, spaceLayerActive, lastDKeyTime, altTabMenuOpen, isRDP

    ; 다른 키가 눌렸음을 기록
    if (!spaceOtherKeyPressed)
    {
        spaceOtherKeyPressed := true
        spaceFirstOtherKeyTime := A_TickCount
        LogKeyEvent("SPACE_OTHER_KEY_FIRST", "key=" keyName " | firstOtherKeyTime=" spaceFirstOtherKeyTime)
        LogKeyStateAnalysis("Space 레이어에서 첫 키 감지: " keyName)
    }

    ; 인정 시각 계산
    qualifyAt := CalculateSpaceQualifyTime()
    currentTime := A_TickCount

    LogKeyEvent("SPACE_KEY_HANDLER", "key=" keyName " | action=" action " | qualifyAt=" qualifyAt " | currentTime=" currentTime " | qualified=" spaceLayerQualified)

    ; 이미 인정되었거나 조건을 만족하는 경우 즉시 실행
    if (spaceLayerQualified || currentTime >= qualifyAt)
    {
        spaceLayerQualified := true
        LogKeyEvent("SPACE_KEY_QUALIFIED", "key=" keyName " | action=" action " | executing immediately")
        ExecuteSpaceLayerAction(keyName, action)
        return
    }

    ; 조건을 아직 만족하지 않음 - 지연 대기
    waitTime := qualifyAt - currentTime
    if (waitTime > 0)
    {
        LogKeyEvent("SPACE_KEY_DELAY", "key=" keyName " | waiting " waitTime "ms until qualifyAt=" qualifyAt)

        ; 지정 시간만큼 대기 (키가 여전히 눌려있는지 확인)
        Sleep waitTime

        ; 대기 후에도 Space와 해당 키가 눌려있고 인정 조건을 만족하면 실행
        if (GetKeyState("Space", "P") && GetKeyState(keyName, "P") && (A_TickCount >= qualifyAt || spaceLayerQualified))
        {
            spaceLayerQualified := true
            LogKeyEvent("SPACE_KEY_QUALIFIED_AFTER_DELAY", "key=" keyName " | action=" action " | executing after delay")
            ExecuteSpaceLayerAction(keyName, action)
            LogKeyEvent("SPACE_KEY_EXECUTED", "key=" keyName " | delayed execution successful")
            return
        }
    }

    ; 조건을 만족하지 못했거나 키가 떼어짐 - 패스스루 처리
    LogKeyEvent("SPACE_KEY_PASSTHROUGH_START", "key=" keyName " | condition not met, preparing passthrough")
    LogKeyStateAnalysis("패스스루 준비: " keyName)

    ; 수식키 상태를 고려해서 원래 키를 다시 전송
    modifiers := ""
    if GetKeyState("Shift", "P")
        modifiers .= "+"
    if GetKeyState("Ctrl", "P")
        modifiers .= "^"
    if GetKeyState("Alt", "P") && !GetKeyState("LAlt", "P")  ; 오른쪽 Alt만 (한영키 제외)
        modifiers .= "!"

    ; 원래 키 입력으로 패스스루
    finalKey := ""
    if (keyName = "Enter")
        finalKey := modifiers . "{Enter}"
    else
        finalKey := modifiers . "{" . keyName . "}"
    
    LogKeyEvent("SPACE_KEY_PASSTHROUGH_SEND", "key=" keyName " | modifiers=" modifiers " | sending=" finalKey)
    
    Send finalKey
    
    LogKeyEvent("SPACE_KEY_PASSTHROUGH_COMPLETE", "key=" keyName " | passthrough complete")
}

; Space 레이어 액션 실행
ExecuteSpaceLayerAction(keyName, action)
{
    global spaceUsedWithOtherKey, altTabMenuOpen, isRDP, lastDKeyTime

    ; 매핑 실행 표시
    spaceUsedWithOtherKey := true

    LogKeyEvent("EXEC_SPACE_ACTION_START", "key=" keyName " | action=" action " | timeMs=" A_TickCount)
    LogKeyStateAnalysis("SpaceLayerAction 실행 중: " keyName " -> " action)

    ; 액션에 따른 실행
    if (action = "{Up}" || action = "{Left}" || action = "{Down}" || action = "{Right}" ||
        action = "{PgUp}" || action = "{PgDn}" || action = "{Home}" || action = "{End}" ||
        action = "{Delete}" || action = "{Esc}")
    {
        ; 기본 SendKey 액션들
        LogKeyEvent("HOTKEY_EXEC", "Space+" keyName " | mappedTo=" action)
        SendKey(action)
    }
    else if (action = "AltTab")
    {
        ; d 키의 Alt+Tab 특별 처리
        currentTime := A_TickCount

        ; 디바운싱: 마지막 d 키 입력 후 100ms 이내면 무시
        if (currentTime - lastDKeyTime < 100)
        {
            LogKeyEvent("ALTTAB_DEBOUNCE", "ignoring duplicate d key press within 100ms")
            return
        }

        lastDKeyTime := currentTime

        ; Shift가 눌렸는지 확인 (역방향 Alt+Tab)
        shiftPressed := GetKeyState("Shift", "P")
        altTabDirection := shiftPressed ? "Alt+Shift+Tab" : "Alt+Tab"

        LogKeyEvent("HOTKEY_EXEC", "Space+d | mappedTo=" altTabDirection)

        altTabMenuOpen := true

        ; 원격 데스크톱 환경 감지 (활성화된 경우만 RDP 모드)
        ; WinActive를 사용하여 최소화된 RDP 창은 로컬 모드로 처리
        isRDP := WinActive("ahk_class TscShellContainerClass")

        LogKeyEvent("ALTTAB_CONTEXT", "isRDP=" isRDP " | shiftPressed=" shiftPressed)

        if (isRDP)
        {
            ; 원격 데스크톱: SendInput 모드로 더 신뢰성 있게 전송
            ; Alt 키를 먼저 누르고 충분한 지연 후 Tab 전송 (Shift가 눌렸으면 Shift도 포함)
            SendInput "{LAlt down}"
            if (shiftPressed)
                SendInput "{Shift down}"
            Sleep 20
            SendInput "{Tab}"
            if (shiftPressed)
                SendInput "{Shift up}"
            LogKeyEvent("ALTTAB_RDP", "sent via RDP mode")
        }
        else
        {
            ; 로컬 환경: 기존 방식 사용 (최소화된 RDP 포함)
            ; Shift가 눌렸으면 Alt+Shift+Tab으로 역방향 전송
            if (shiftPressed)
                Send "{Alt down}{Shift down}{Tab}{Shift up}"
            else
                Send "{Alt down}{Tab}"
            LogKeyEvent("ALTTAB_LOCAL", "sent via local mode")
        }
    }
    else if (action = "Ctrls")
    {
        ; s 키의 특별 처리 (Alt+Tab 메뉴 상태 고려)
        if (altTabMenuOpen)
        {
            LogKeyEvent("HOTKEY_EXEC", "Space+s | in Alt+Tab menu | sending={Left}")
            Send "{Left}"
        }
        else
        {
            LogKeyEvent("HOTKEY_EXEC", "Space+s | sending=Ctrl+s")
            SendKeyWithCtrl("s")
        }
    }
    else if (action = "Ctrlf")
    {
        ; f 키의 특별 처리 (Alt+Tab 메뉴 상태 고려)
        if (altTabMenuOpen)
        {
            LogKeyEvent("HOTKEY_EXEC", "Space+f | in Alt+Tab menu | sending={Right}")
            Send "{Right}"
        }
        else
        {
            LogKeyEvent("HOTKEY_EXEC", "Space+f | sending=Ctrl+f")
            SendKeyWithCtrl("f")
        }
    }
    else if (InStr(action, "Ctrl"))
    {
        ; Ctrl+키 액션들
        key := StrReplace(action, "Ctrl", "")
        key := StrReplace(key, "Enter", "{Enter}")

        LogKeyEvent("HOTKEY_EXEC", "Space+" keyName " | mapped=" action " | extractedKey=" key)
        SendKeyWithCtrl(key)
    }
    
    LogKeyEvent("EXEC_SPACE_ACTION_END", "key=" keyName " | action=" action " | completed at " A_TickCount)
}

; Space 단독 홀드 인정 타이머 (500ms 경과 시 레이어 인정)
SpaceSoloQualifyTimer()
{
    global spaceLayerQualified, spaceLayerActive

    ; Space가 아직 눌려있고 레이어가 활성화된 상태에서만 인정
    if (spaceLayerActive && GetKeyState("Space", "P"))
    {
        spaceLayerQualified := true
        LogKeyEvent("SPACE_SOLO_QUALIFIED", "Space held for 500ms, layer qualified")
    }

    ; 타이머는 일회성으로 실행 후 제거
    SetTimer(, 0)
}
