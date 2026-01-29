; ============================================
; Layer State and Rules Module
; ============================================

; ============================================
; 레이어 시스템 상수 및 변수
; ============================================

; 레이어 상수 정의 (VIA 스타일 명명)
global LAYER_BASE := "Base"           ; 기본 레이어 (레이어 키 누르지 않은 상태)
global LAYER_MOUSE := "Mouse"         ; CapsLock 레이어 (마우스 제어 및 매크로)
global LAYER_NAV := "Navigation"      ; Space 레이어 (내비게이션 및 단축키)

; 레이어 상태 추적
global currentLayer := LAYER_BASE     ; 현재 활성화된 레이어
global capsLockLayerActive := false   ; CapsLock 레이어 활성 상태
global spaceLayerActive := false      ; Space 레이어 활성 상태

; 레이어 활성화 시간 추적 (의도하지 않은 활성화 방지)
global capsLockActivationTime := 0
global spaceActivationTime := 0
global capsLockMinHoldTime := 100      ; CapsLock 레이어 최소 홀드 시간 (ms)
global spaceMinHoldTime := 200         ; Space 레이어 최소 홀드 시간 (ms)

; ============================================
; 레이어 상태 관리 함수
; ============================================

; 현재 활성화된 레이어 반환 (우선순위: MOUSE > NAV > BASE)
GetCurrentLayer()
{
    global LAYER_BASE, LAYER_MOUSE, LAYER_NAV
    global capsLockLayerActive, spaceLayerActive

    ; CapsLock 레이어가 최우선 순위
    ; NOTE: CapsLock 물리 상태(P) 판정이 불안정한 환경이 있어 레이어 플래그만 기준으로 삼는다.
    if (capsLockLayerActive)
        return LAYER_MOUSE

    ; Space 레이어가 두 번째 우선순위
    if (spaceLayerActive)
        return LAYER_NAV

    ; 기본 레이어
    return LAYER_BASE
}

; 특정 레이어가 활성 상태인지 확인
IsLayerActive(layerName)
{
    global LAYER_BASE, LAYER_MOUSE, LAYER_NAV
    global capsLockLayerActive, spaceLayerActive

    if (layerName = LAYER_MOUSE)
        return capsLockLayerActive
    else if (layerName = LAYER_NAV)
        return spaceLayerActive
    else if (layerName = LAYER_BASE)
        return !capsLockLayerActive && !spaceLayerActive

    return false
}

; 레이어 활성화 (타이밍 검증 포함)
ActivateLayer(layerName)
{
    global LAYER_MOUSE, LAYER_NAV
    global capsLockLayerActive, spaceLayerActive
    global capsLockActivationTime, spaceActivationTime
    global currentLayer

    currentTime := A_TickCount

    if (layerName = LAYER_MOUSE)
    {
        capsLockLayerActive := true
        capsLockActivationTime := currentTime
        currentLayer := LAYER_MOUSE
    }
    else if (layerName = LAYER_NAV)
    {
        spaceLayerActive := true
        spaceActivationTime := currentTime
        currentLayer := LAYER_NAV
    }

    ; 레이어 변경 시 PC 식별 ToolTip 표시
    ShowLayerTooltip(layerName, "ON")

    ; 로깅: 레이어 활성화
    LogKeyEvent("LAYER_ACTIVATE", layerName " | activationTime=" currentTime)
}

; 레이어 안전하게 비활성화
DeactivateLayer(layerName)
{
    global LAYER_BASE, LAYER_MOUSE, LAYER_NAV
    global capsLockLayerActive, spaceLayerActive
    global capsLockActivationTime, spaceActivationTime
    global currentLayer

    if (layerName = LAYER_MOUSE)
    {
        capsLockLayerActive := false
        capsLockActivationTime := 0
    }
    else if (layerName = LAYER_NAV)
    {
        spaceLayerActive := false
        spaceActivationTime := 0
    }

    ; 현재 레이어 재계산
    currentLayer := GetCurrentLayer()

    ; 레이어 변경 시 PC 식별 ToolTip 표시 (비활성화 후 현재 활성 레이어 표시)
    ShowLayerTooltip(currentLayer, "ON")

    ; 로깅: 레이어 비활성화
    LogKeyEvent("LAYER_DEACTIVATE", layerName)
}

; 모든 레이어를 기본 상태로 강제 초기화
ForceResetAllLayers()
{
    global LAYER_BASE, capsLockLayerActive, spaceLayerActive
    global capsLockActivationTime, spaceActivationTime
    global currentLayer
    global spaceLayerQualified, spaceOtherKeyPressed, spaceFirstOtherKeyTime

    capsLockLayerActive := false
    spaceLayerActive := false
    capsLockActivationTime := 0
    spaceActivationTime := 0
    spaceLayerQualified := false
    spaceOtherKeyPressed := false
    spaceFirstOtherKeyTime := 0
    currentLayer := LAYER_BASE

    ; 물리적으로 눌려있는 레이어 키들 해제
    if GetKeyState("CapsLock", "P")
        Send "{CapsLock up}"
    if GetKeyState("Space", "P")
        Send "{Space up}"
}

; 레이어가 충분히 오래 눌렸는지 확인 (의도하지 않은 활성화 방지)
IsLayerHeldLongEnough(layerName)
{
    global LAYER_MOUSE, LAYER_NAV
    global capsLockActivationTime, spaceActivationTime
    global capsLockMinHoldTime, spaceMinHoldTime

    currentTime := A_TickCount

    if (layerName = LAYER_MOUSE)
    {
        if (capsLockActivationTime = 0)
        {
            LogKeyEvent("LAYER_HOLD_CHECK", layerName " | activationTime=0 | FAILED")
            return false
        }
        holdTime := currentTime - capsLockActivationTime
        passed := holdTime >= capsLockMinHoldTime
        LogKeyEvent("LAYER_HOLD_CHECK", layerName " | holdTime=" holdTime "ms | " (passed ? "PASSED" : "FAILED"))
        return passed
    }
    else if (layerName = LAYER_NAV)
    {
        if (spaceActivationTime = 0)
        {
            LogKeyEvent("LAYER_HOLD_CHECK", layerName " | activationTime=0 | FAILED")
            return false
        }
        holdTime := currentTime - spaceActivationTime
        passed := holdTime >= spaceMinHoldTime
        LogKeyEvent("LAYER_HOLD_CHECK", layerName " | holdTime=" holdTime "ms | " (passed ? "PASSED" : "FAILED"))
        return passed
    }

    return true
}
