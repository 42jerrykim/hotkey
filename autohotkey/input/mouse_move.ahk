; ============================================
; Mouse Movement Module
; ============================================

; 마우스 이동 관련 전역 변수
global isMouseMoving := false
global moveX := 0
global moveY := 0
global moveInterval := 10  ; 밀리초 단위 업데이트 간격
global lastVerticalKey := ""  ; 마지막으로 눌린 수직 방향 키 (i 또는 k)
global lastHorizontalKey := ""  ; 마지막으로 눌린 수평 방향 키 (j 또는 l)

; 마우스 이동 가속도 관련 변수
global keyHoldStartTime := 0  ; 키를 누르기 시작한 시간
global minMoveSpeed := 1  ; 최저 속도 (픽셀)
global maxMoveSpeed := 100  ; 최고 속도 (픽셀)
global accelerationDuration := 2000  ; 최고 속도까지 도달하는 시간 (밀리초)

; 현재 눌려있는 키에 따라 이동 방향 업데이트
UpdateMoveDirection()
{
    global moveX, moveY, lastVerticalKey, lastHorizontalKey

    ; Y축 방향 확인 (i: 위, k: 아래)
    if (GetKeyState("i", "P") && !GetKeyState("k", "P"))
        moveY := -1
    else if (GetKeyState("k", "P") && !GetKeyState("i", "P"))
        moveY := 1
    else if (GetKeyState("i", "P") && GetKeyState("k", "P"))
    {
        ; 둘 다 눌렸으면 마지막으로 눌린 키 우선
        if (lastVerticalKey = "i")
            moveY := -1
        else if (lastVerticalKey = "k")
            moveY := 1
        else
            moveY := 0
    }
    else
        moveY := 0

    ; X축 방향 확인 (j: 왼쪽, l: 오른쪽)
    if (GetKeyState("j", "P") && !GetKeyState("l", "P"))
        moveX := -1
    else if (GetKeyState("l", "P") && !GetKeyState("j", "P"))
        moveX := 1
    else if (GetKeyState("j", "P") && GetKeyState("l", "P"))
    {
        ; 둘 다 눌렸으면 마지막으로 눌린 키 우선
        if (lastHorizontalKey = "j")
            moveX := -1
        else if (lastHorizontalKey = "l")
            moveX := 1
        else
            moveX := 0
    }
    else
        moveX := 0

    ; 모든 키가 눌리지 않았으면 타이머 중지
    if (moveX = 0 && moveY = 0)
        StopMouseMove()
}

; 마우스 이동 시작
StartMouseMove()
{
    global isMouseMoving, keyHoldStartTime
    if (!isMouseMoving)
    {
        isMouseMoving := true
        keyHoldStartTime := A_TickCount  ; 키 누름 시간 기록
        SetTimer(MoveMouseContinuously, moveInterval)
    }
}

; 마우스 이동 중지
StopMouseMove()
{
    global isMouseMoving, moveX, moveY, lastVerticalKey, lastHorizontalKey, keyHoldStartTime
    if (isMouseMoving)
    {
        SetTimer(MoveMouseContinuously, 0)
        isMouseMoving := false
    }
    moveX := 0
    moveY := 0
    lastVerticalKey := ""
    lastHorizontalKey := ""
    keyHoldStartTime := 0  ; 시간 초기화
}

; 연속적으로 마우스 이동
MoveMouseContinuously()
{
    global moveX, moveY
    global keyHoldStartTime, minMoveSpeed, maxMoveSpeed, accelerationDuration
    global capsLockLayerActive

    ; 캡스락 키가 눌려있고 이동 방향이 있을 때만 이동
    ; NOTE: CapsLock 물리 상태(P) 판정이 불안정한 환경이 있어 레이어 플래그 기준으로 동작시킨다.
    if (capsLockLayerActive && (moveX != 0 || moveY != 0))
    {
        ; 경과 시간 계산 (밀리초)
        elapsedTime := A_TickCount - keyHoldStartTime

        ; 비선형 가속도 계산 (이차 함수): minMoveSpeed에서 maxMoveSpeed까지
        ; 공식: currentSpeed = minMoveSpeed + (maxMoveSpeed - minMoveSpeed) * (min(경과시간 / accelerationDuration, 1))^2
        accelerationFactor := Min(elapsedTime / accelerationDuration, 1)
        currentSpeed := minMoveSpeed + (maxMoveSpeed - minMoveSpeed) * (accelerationFactor ** 2)

        MouseMove(moveX * currentSpeed, moveY * currentSpeed, 0, "R")
    }
    else
    {
        StopMouseMove()
    }
}
