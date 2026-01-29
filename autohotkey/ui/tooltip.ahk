; ============================================
; UI Feedback Module
; ============================================

; ============================================
; ToolTip 표시 관련 설정
; ============================================

; ToolTip 표시 시간 (밀리초)
global tooltipDisplayTime := 1200

; ToolTip 위치 (화면 우측 하단)
global tooltipX := A_ScreenWidth - 300
global tooltipY := A_ScreenHeight - 100

; 중복 표시 방지용 마지막 표시 시간 및 내용
global lastTooltipTime := 0
global lastTooltipLayer := ""
global lastTooltipState := ""
global tooltipCooldownMs := 300  ; 같은 내용 표시 간 최소 간격 (ms)

; ============================================
; ToolTip 표시 함수
; ============================================

; 레이어 변경 시 PC 식별 ToolTip 표시
ShowLayerTooltip(layerName, state)
{
    global lastTooltipTime, lastTooltipLayer, lastTooltipState
    global tooltipCooldownMs, tooltipDisplayTime, tooltipX, tooltipY

    ; 중복 표시 방지: 같은 내용이 아주 최근에 표시되었다면 스킵
    currentTime := A_TickCount
    if (layerName = lastTooltipLayer && state = lastTooltipState &&
        (currentTime - lastTooltipTime) < tooltipCooldownMs)
    {
        return
    }

    ; 표시할 텍스트 구성
    tooltipText := "PC=" A_ComputerName " / User=" A_UserName " / Layer=" layerName " (" state ")"

    ; ToolTip 표시
    ToolTip(tooltipText, tooltipX, tooltipY)

    ; 마지막 표시 정보 업데이트
    lastTooltipTime := currentTime
    lastTooltipLayer := layerName
    lastTooltipState := state

    ; 지정 시간 후 ToolTip 자동 숨김
    SetTimer(() => ToolTip(), -tooltipDisplayTime)
}
