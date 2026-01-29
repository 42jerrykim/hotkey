; ============================================
; Space Layer Hotkeys Module
; ============================================

; ============================================
; 스페이스 바 + IJKL로 방향키 입력
; ============================================

; 스페이스 바가 눌린 상태에서의 키 매핑 (지연 실행 필터 적용)
#HotIf GetKeyState("Space", "P")

; Space + I (위로)
*i::HandleSpaceLayerKey("i", "{Up}")

; Space + J (왼쪽으로)
*j::HandleSpaceLayerKey("j", "{Left}")

; Space + K (아래로)
*k::HandleSpaceLayerKey("k", "{Down}")

; Space + L (오른쪽으로)
*l::HandleSpaceLayerKey("l", "{Right}")

; y -> PgUp (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*y::HandleSpaceLayerKey("y", "{PgUp}")

; h -> PgDn (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*h::HandleSpaceLayerKey("h", "{PgDn}")

; u -> Home (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*u::HandleSpaceLayerKey("u", "{Home}")

; o -> End (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*o::HandleSpaceLayerKey("o", "{End}")

; p -> Delete (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*p::HandleSpaceLayerKey("p", "{Delete}")

; d -> Alt + Tab 메뉴 열기 (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*d::HandleSpaceLayerKey("d", "AltTab")

; q -> Esc (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*q::HandleSpaceLayerKey("q", "{Esc}")

; w -> Ctrl + w (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*w::HandleSpaceLayerKey("w", "Ctrlw")

; e -> Ctrl + e (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*e::HandleSpaceLayerKey("e", "Ctrle")

; r -> Ctrl + r (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*r::HandleSpaceLayerKey("r", "Ctrlr")

; t -> Ctrl + t (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*t::HandleSpaceLayerKey("t", "Ctrlt")

; a -> Ctrl + a (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*a::HandleSpaceLayerKey("a", "Ctrla")

; s -> Ctrl + s 또는 Left (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*s::HandleSpaceLayerKey("s", "Ctrls")

; f -> Ctrl + f 또는 Right (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*f::HandleSpaceLayerKey("f", "Ctrlf")

; z -> Ctrl + z (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*z::HandleSpaceLayerKey("z", "Ctrlz")

; x -> Ctrl + x (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*x::HandleSpaceLayerKey("x", "Ctrlx")

; c -> Ctrl + c (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*c::HandleSpaceLayerKey("c", "Ctrlc")

; v -> Ctrl + v (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*v::HandleSpaceLayerKey("v", "Ctrlv")

; Enter -> Ctrl + Enter (* 와일드카드: Shift/Ctrl 등과 함께 눌러도 작동)
*Enter::HandleSpaceLayerKey("Enter", "CtrlEnter")

#HotIf

; ============================================
; 디버깅용 입력 감시 핫키 (Space 레이어 외부)
; ============================================

; Space 레이어 내부가 아닌 곳에서의 일반 키 입력 감시
; NOTE: CapsLock(Mouse) 레이어와 조건이 겹치면 해당 레이어 핫키를 가로채는 문제가 있어,
;       "Base 레이어"에서만 감시하도록 조건을 좁힌다.
#HotIf !spaceLayerActive && !capsLockLayerActive

~a::
~b::
~c::
~d::
~e::
~f::
~g::
~h::
~i::
~j::
~k::
~l::
~m::
~n::
~o::
~p::
~q::
~r::
~s::
~t::
~u::
~v::
~w::
~x::
~y::
~z::
{
    LogKeyEvent("NORMAL_KEY_INPUT", "key=" A_ThisHotkey " | timeMs=" A_TickCount)
    LogKeyStateAnalysis("일반 입력: " A_ThisHotkey)
}

#HotIf