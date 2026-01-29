; ============================================
; Configuration Loading Module
; ============================================

; ============================================
; 설정 파일 로드 (민감정보)
; ============================================

; secrets.ini에서 설정 값 읽기
LoadSecretConfig()
{
    global capsLockText1 := ""
    global capsLockText2 := ""
    global capsLockText3 := ""

    configFile := A_ScriptDir "\secrets.ini"

    ; 설정 파일이 없으면 경고 후 빈 값으로 진행
    if (!FileExist(configFile))
    {
        MsgBox("secrets.ini 파일을 찾을 수 없습니다. 민감 텍스트 매크로가 작동하지 않습니다.`n`n파일을 생성하여 [TextMacros] 섹션에 다음 키를 추가하세요:`ncaps_1=...`ncaps_2=...`ncaps_3=...", "설정 파일 누락", "Icon!")
        return
    }

    try
    {
        ; 설정 값 읽기
        capsLockText1 := IniRead(configFile, "TextMacros", "caps_1", "")
        capsLockText2 := IniRead(configFile, "TextMacros", "caps_2", "")
        capsLockText3 := IniRead(configFile, "TextMacros", "caps_3", "")

        ; 로깅 (값 자체는 기록하지 않음)
        LogKeyEvent("CONFIG_LOADED", "secrets.ini loaded successfully")
    }
    catch
    {
        MsgBox("secrets.ini 파일을 읽는 중 오류가 발생했습니다.", "설정 파일 오류", "Icon!")
    }
}
