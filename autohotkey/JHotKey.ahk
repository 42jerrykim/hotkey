#Requires AutoHotkey v2.0

; ============================================
; Main Entry Point - AutoHotKey Script
; ============================================

; 관리자 권한으로 실행되지 않았다면 관리자 권한으로 재시작
; if not A_IsAdmin
; {
;     Run '*RunAs "' A_ScriptFullPath '"'
;     ExitApp
; }

; 모든 핫키에 키보드 후킹 사용 (기본 동작 완전 차단)
#UseHook

; Alt 키의 메뉴 활성화 방지 (조합 핫키가 기본 Alt 동작을 무시하도록)
A_MenuMaskKey := "vkFF"
 
; 캡스락 기본 기능 비활성화
SetCapsLockState "AlwaysOff"

; Include all modules in correct order (globals first, then functions, then hotkeys)
#include "layers\state.ahk"          ; Layer constants and state variables (must be first)
#include "config\secrets.ahk"        ; Configuration loading
#include "logging\logger.ahk"        ; Logging functions
#include "ui\tooltip.ahk"            ; UI feedback functions
#include "layers\space_qualify.ahk"  ; Space layer qualification logic
#include "input\send_helpers.ahk"    ; Input sending utilities
#include "input\mouse_move.ahk"      ; Mouse movement functions
#include "system\focus_monitor.ahk"  ; Window focus monitoring and resets

; Include hotkey definitions (must be last)
#include "hotkeys\base_hotkeys.ahk"      ; Base layer hotkeys (CapsLock, Space, Alt+Tab, etc.)
#include "hotkeys\capslock_hotkeys.ahk"  ; CapsLock layer hotkeys
#include "hotkeys\space_hotkeys.ahk"     ; Space layer hotkeys

; ============================================
; Bootstrap/Initialization
; ============================================

; Load configuration (must be done early)
LoadSecretConfig()

; Start window focus monitoring timer (50ms interval)
SetTimer(CheckWindowFocus, 50)
