# 원격 포커스 전환 시 모디파이어(Ctrl 등)가 눌린 채로 남는 문제

## 증상

host PC에서 remote PC(원격 데스크톱, mstsc)로 포커스를 이동했을 때, remote 쪽에서 Ctrl이 눌려있는 것처럼 동작하는 경우가 있다. 사용자는 포커스 전환 시 모디파이어를 누른 채로 이동하지 않는다고 확인했으므로, 원인은 "전환 순간의 물리적 홀드"가 아니라 그 이전의 키 입력에서 비롯된 지연된 release로 추정된다.

## 분석에 사용한 로그

- remote 로그: `log/kanata_JONG-MIN-KIM06_20260928_084650.log` (그 외 `log/` 내 다른 날짜 로그도 동일 패턴 확인)
- host 로그: `logsHost/kanata_JONG-MIN-KIM03_20260928_084713.log`

## 1차 분석에서 기각한 가설

`log/` 폴더의 remote 로그만 볼 때 다음과 같은 burst 패턴이 반복적으로 관찰된다.

```
event loop: KeyEvent { code: KEY_TAB, value: Release }
forwarding release of never-seen press KeyEvent { code: KEY_TAB, value: Release }
... (LShift, RShift, LCtrl, RCtrl, LAlt, RAlt 동일 패턴 반복) ...
```

이 패턴은 mstsc(원격 데스크톱 클라이언트)가 세션 포커스가 바뀔 때 "혹시 눌려있을지 모르는" 모디파이어들을 일괄적으로 release 신호로 밀어 넣는 자체 동기화 동작이다. kanata 입장에서는 press를 본 적 없는 release이므로 forwarding만 하고 실질적인 상태 변화는 없다.

state machine이 실제로 만들어낸 LCtrl press/release 카운트를 집계해보면 모든 로그에서 정확히 짝이 맞는다(RCtrl은 만든 적 자체가 없음). 즉 kanata의 home row mods(tap-hold) 로직 자체가 Ctrl을 누른 채로 방치하는 사례는 로그에서 확인되지 않았다. 이 가설은 기각.

## 근본 원인

host와 remote 로그를 같은 시간대로 대조한 결과, 결정적 증거를 host 로그에서 발견했다.

```
08:58:53.6919  KEY_LEFTMETA (91), Press     ← Win 키를 실제로 누름
08:58:53.6922  key press     LGui           ← kanata가 Win을 "눌림" 상태로 기록
   ... (이후 3분 22초 동안 이 키보드에서 어떤 이벤트도 로그에 없음) ...
09:02:15.3732  KEY_LEFTMETA (91), Release   ← 그제서야 release 도착
09:02:15.3734  key release   LGui
```

Win 키를 3분 22초간 물리적으로 누르고 있었을 리는 없다. 실제로 벌어진 일은 다음과 같이 추정된다.

1. Win 키를 눌러 시작 메뉴 같은 시스템 UI(보안/포커스 경계가 있는 표면)가 뜬 시점에 물리적으로는 이미 키를 뗐다.
2. 그런데 그 release 이벤트가 저수준 훅(kanata의 llhook)에 즉시 전달되지 않고 Windows 쪽에서 버퍼링되었다.
3. 09:02:15에 발생한 mstsc 세션 포커스 전환 burst(TAB → Shift → Ctrl → Meta → Alt 순으로 몰려서 release가 도착하는 그 패턴) 시점에 뒤늦게 몰아서 전달됐다.

즉 Win 키를 오래 쥐고 있었던 게 아니라 release 이벤트 자체가 지연·버퍼링되었고, 그게 하필 remote로 포커스가 넘어가는 순간에 몰아서 도착한 것이다. 이 메커니즘이 Meta(Win) 대신 Ctrl에서 발생하면 정확히 사용자가 보고한 증상이 된다.

## 재현 조건 추정

Ctrl 계열에서 같은 현상이 나려면 다음과 같은 흐름이 유력하다.

1. `hrm-f`/`hrm-j`(f, j 키를 홀드하면 Ctrl로 동작, [bin/kanata.kbd:165](../bin/kanata.kbd)와 [bin/kanata.kbd:168](../bin/kanata.kbd))로 Ctrl 조합(예: Ctrl+클릭, 컨텍스트 메뉴 등)을 사용한다.
2. 키보드로 명시적으로 해제(Esc 등)하지 않고 마우스로 다른 창이나 remote 세션을 클릭해서 포커스를 옮긴다.
3. 그 물리적 release가 Windows UI 경계(시작 메뉴, 컨텍스트 메뉴, UAC 등) 때문에 지연되어 kanata 내부에 Ctrl이 눌린 채로 남는다.
4. remote로 포커스가 넘어가는 순간 그 상태가 함께 넘어가거나 flush되면서 remote 쪽에서 Ctrl이 눌린 것처럼 동작한다.

## kanata 자체의 안전장치

`clearing keyberon normal key states due to inactivity` 로그가 host/remote 양쪽에서 반복 확인된다. 이는 kanata에 내장된 자체 워치독으로, 일정 시간 입력이 없으면 내부적으로 눌려있던 키 상태를 강제로 정리한다. 다만 이 정리가 발동하기까지 수 분이 걸릴 수 있고, 하필 다음 의미 있는 이벤트(mstsc 포커스 전환 burst)와 타이밍이 겹치면서 "전환 시점에 문제가 생긴 것처럼" 보이게 된다.

수동 해제 수단으로는 `mrls`([bin/kanata.kbd:177](../bin/kanata.kbd))가 이미 존재한다. nav 레이어의 B 키에 바인딩되어 있으며, lalt/ralt/lctl/rctl/lsft/rsft/lmet/rmet을 모두 강제로 release한다.

## 적용된 대응

### mstsc 포커스 전환 자동 감지 → 자동 해제

`bin/kanata.cmd`에 인라인 PowerShell 워처(focus watcher)를 추가했다. foreground window를 250ms 간격으로 폴링하다가 프로세스명이 `mstsc`로 전환되는 "엣지"를 감지하면, kanata의 TCP 서버(`127.0.0.1:7070`, `--port` 인자로 활성화)에 `{"ActOnFakeKey":{"name":"mrls-auto","action":"Tap"}}`를 전송해 `bin/kanata.kbd`에 추가한 `defvirtualkeys mrls-auto`(기존 `mrls`와 동일한 강제 release 액션)를 즉시 트리거한다.

- kanata의 느린 `inactivity` 정리 타이머(수 분 단위, 아래 "검토했지만 채택하지 않은 방안" 참고)에 의존하지 않고, mstsc 포커스 전환 시점에 즉시 개입한다.
- `mrls-auto`는 `release-key`만 사용하므로 press 이벤트를 만들지 않는다. 즉 `@han`(한영전환, `ralt`의 press에만 반응)을 직접 트리거하지 않는다 — 자세한 검토는 아래 "위험 검토" 참고.
- 워처 로그는 `[FocusWatcher]` 태그를 붙여 kanata 본 로그와 같은 파일(`%LOGFILE%`)에 함께 남는다.

### CapsLock 보정 워처 폴링 간격 단축 + 로깅

기존 CapsLock lock-state 보정 워처(60초 간격)를 focus watcher와 같은 `POLL_INTERVAL_MS=250`(250ms)으로 통일했다. `IsKeyLocked`/`GetForegroundWindow` 모두 가벼운 API 호출이라 이 정도 간격에서 CPU 부담은 무시할 수준이다.

로그 파일 경로를 `bin/kanata.cmd` 최상단에서 한 번만 계산해 `%LOGFILE%`로 고정하고, `start`로 띄우는 하위 워처 프로세스들이 이를 상속받아 `[CapsWatcher]`/`[FocusWatcher]` 태그로 직접 append하도록 바꿨다. 기존에는 kanata.exe의 출력만 로그 파일에 남고 워처들의 동작은 어디에도 기록되지 않았다.

## 위험 검토

- **CapsLock 보정 워처의 한영전환 오탐 가능성**: CapsLock 워처는 `IsKeyLocked`가 true일 때 `SendKeys('{CAPSLOCK}')`로 합성 CapsLock 입력을 주입한다. CapsLock 탭은 VK_HANGUL(`arbitrary-code 21`, [bin/kanata.kbd:97](../bin/kanata.kbd))을 전송하도록 매핑되어 있어, kanata의 저수준 훅이 이 합성 입력도 가로챌 경우 "탭"으로 재해석되어 mstsc 포커스 상태에서 remote로 한영전환이 전달될 가능성이 있다. `mrls-auto`(release-key만 사용)는 이 위험에서 제외된다. 폴링 간격을 250ms로 단축하면서 이 경로의 발생 빈도도 늘어날 수 있어, 검증 절차(아래)로 실재 여부를 확인해야 한다.
- **remote→host 역방향 오염 가능성**: 검토 결과 위험 없음. host가 mstsc로 remote를 단방향 원격 제어하는 구조라 RDP 키보드 리다이렉션이 host→remote로만 흐르고, remote의 로컬 보정(CapsLock 워처, mrls, focus watcher)이 host로 역전파될 경로가 없다.
- **TCP 서버 개방**: `127.0.0.1`에만 바인딩되어 외부 네트워크 노출은 없지만, 로컬의 다른 프로세스가 `ActOnFakeKey`/`ChangeLayer`를 임의로 트리거할 수 있게 된다는 점은 감안해야 한다.
- **폴링 방식의 한계**: 포커스 전환 감지가 250ms 폴링 주기만큼 지연될 수 있다 — 기존 문제(수 분 지연)보다는 압도적으로 개선되지만 완전히 즉시는 아니다.
- **오탐(false trigger)**: mstsc 창이 여러 개거나 RemoteApp 모드처럼 프로세스명이 다른 경우 감지가 안 될 수 있다. 초기 구현은 프로세스명 `mstsc` 매칭만 지원한다.

## 검증 절차

1. `deploy_kanata_cmd.bat` 실행 후 `kanata.cmd` 재시작 → 로그 파일 하나에 kanata.exe 출력과 `[CapsWatcher]`/`[FocusWatcher]` 태그 줄이 시간순으로 함께 쌓이는지 확인.
2. `hrm-f`(f 홀드 → Ctrl)로 컨텍스트 메뉴를 띄운 뒤 키보드로 닫지 않고 마우스로 mstsc 창 클릭 → mstsc 쪽에서 곧바로 문자 입력이 정상 동작(Ctrl 오인식 없음)하는지 확인. 로그에서 `[FocusWatcher]` 트리거 직후 modifier release가 이어지는지 함께 확인.
3. 워처 두 개(`CAPSPIDFILE`, `FOCUSPIDFILE`) 모두 `kanata.cmd` 종료 시 함께 종료되는지 확인.
4. CapsLock 워처 한영전환 오탐 검증:
   a. 대조군 — kanata 없이 `(New-Object -ComObject WScript.Shell).SendKeys('{CAPSLOCK}')` 수동 실행, `IsKeyLocked('CapsLock')` 전후 비교.
   b. kanata 실행 중 같은 SendKeys를 수동 실행하며 로그에 `KEY_CAPSLOCK (20)` Press/Release가 찍히는지 확인(가로채짐 여부).
   c. host에서 mstsc에 포커스를 둔 채 언어 상태를 미리 확인한 뒤 같은 SendKeys를 실행 → 한/영이 바뀌는지 육안 확인(로그에는 `arbitrary-code` 출력이 이름 붙어 남지 않는 것으로 보이므로 육안 확인 필요).
   d. 재현되면 CapsLock 보정 방식 자체를 재검토.

## 검토했지만 채택하지 않은 방안

- kanata의 `inactivity` 정리 타이머 단축: kbd 설정으로 노출되어 있지 않아 조정 불가로 확인. 대신 focus watcher로 별도 트리거 경로를 마련하는 쪽을 택함.
- Win/Ctrl 조합으로 뜬 메뉴를 마우스 클릭이 아니라 Esc로 닫는 습관: 여전히 유효한 보조 습관이지만, 이번 변경으로 자동 대응이 생겼으므로 필수는 아님.
