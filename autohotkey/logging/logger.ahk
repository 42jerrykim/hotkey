; ============================================
; Logging Module
; ============================================

; ============================================
; 로깅 함수
; ============================================

; 로그 파일명 생성 (일별 파일)
GetLogFileName()
{
    ; 로그 디렉토리 생성 (없으면 자동 생성)
    logDir := A_ScriptDir "\logs"
    if (!DirExist(logDir))
        DirCreate(logDir)

    ; 날짜 기반 파일명 생성 (YYYY-MM-DD)
    dateStr := FormatTime(A_Now, "yyyy-MM-dd")
    return logDir "\keylog_" dateStr ".log"
}

; 키 이벤트 로깅
LogKeyEvent(event, details := "")
{
    try
    {
        ; 타임스탬프 생성 (밀리초 포함)
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss.") . SubStr(A_MSec, 1, 3)

        ; 로그 메시지 조합
        logMsg := "[" timestamp "] " event
        if (details != "")
            logMsg .= " | " details
        logMsg .= "`n"

        ; 로그 파일에 기록
        logFile := GetLogFileName()
        FileAppend(logMsg, logFile, "UTF-8")
    }
    catch
    {
        ; 로깅 실패 시 무시 (스크립트 실행에 영향 주지 않음)
    }
}

; 키 상태 분석 로깅 (한글 처리 관련)
LogKeyStateAnalysis(description)
{
    shiftState := GetKeyState("Shift", "P") ? "ON" : "OFF"
    ctrlState := GetKeyState("Ctrl", "P") ? "ON" : "OFF"
    altState := GetKeyState("Alt", "P") ? "ON" : "OFF"
    laltState := GetKeyState("LAlt", "P") ? "ON" : "OFF"
    capsLockState := GetKeyState("CapsLock", "P") ? "ON" : "OFF"
    spaceState := GetKeyState("Space", "P") ? "ON" : "OFF"
    
    stateInfo := "shift=" shiftState " | ctrl=" ctrlState " | alt=" altState " | lalt=" laltState " | capslock=" capsLockState " | space=" spaceState
    LogKeyEvent("KEY_STATE_CHECK", description " | " stateInfo)
}

; 입력 문자 분석 로깅
LogCharAnalysis(inputStr, description := "")
{
    try
    {
        if (inputStr = "")
            return
        
        charInfo := ""
        Loop StrLen(inputStr)
        {
            char := SubStr(inputStr, A_Index, 1)
            charCode := Ord(char)
            
            ; 한글 유니코드 범위 판정
            isCompleteHangul := (charCode >= 0xAC00 && charCode <= 0xD7A3)  ; 완성 글자
            isHangulJamo := (charCode >= 0x1100 && charCode <= 0x11FF)      ; 자음/모음
            isASCII := charCode < 128
            
            category := isCompleteHangul ? "완성글자" : isHangulJamo ? "자음모음" : isASCII ? "ASCII" : "기타"
            
            if (A_Index > 1)
                charInfo .= " | "
            charInfo .= "[" A_Index "]=" char " (U+" Format("{:04X}", charCode) ", " category ")"
        }
        
        fullDesc := description != "" ? (description " | ") : ""
        LogKeyEvent("CHAR_ANALYSIS", fullDesc charInfo)
    }
    catch
    {
    }
}

; Send 결과 분석 로깅
LogSendDetail(sendStr, context := "")
{
    LogKeyEvent("SEND_DETAIL", context " | output=" sendStr " | length=" StrLen(sendStr) " | tickcount=" A_TickCount)
}