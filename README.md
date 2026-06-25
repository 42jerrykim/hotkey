# hotkey

[Kanata](https://github.com/jtroo/kanata) 기반 키보드 리매핑 설정 모음입니다. 한/영 전환, Home Row Mods, 마우스/내비게이션 레이어 등을 CapsLock과 Space 키에 통합하여 별도의 방향키나 마우스 없이도 빠르게 조작할 수 있도록 구성했습니다.

## 저장소 구조

- [`kanata/`](kanata) — 현재 사용 중인 Kanata 설정 및 실행 스크립트. 메인 구현체입니다.
- [`autohotkey/`](autohotkey) — Kanata로 전환하기 전의 레거시 AutoHotkey v2 구현. 참고용으로 보존 중입니다.

## Kanata 설정 ([`kanata/bin/kanata.kbd`](kanata/bin/kanata.kbd))

3개의 레이어로 구성됩니다.

- **base** — 기본 레이어. CapsLock과 Space에 탭/홀드 동작이 부여됩니다.
  - `CapsLock`: 탭 = 한영 전환, 홀드 = `mouse` 레이어 활성화
  - `Space`: 탭 = 공백, 홀드 = `nav` 레이어 활성화
  - Home Row Mods(AWSC 배치): 왼손 A/S/D/F → Alt/Win/Shift/Ctrl, 오른손 J/K/L/; → Ctrl/Shift/Win/Alt (탭 = 원래 문자, 홀드 = 모디파이어)
- **mouse** (CapsLock 홀드) — 방향키, 스크롤, 마우스 이동/클릭을 키보드에서 직접 처리
- **nav** (Space 홀드) — 방향키, 페이지 이동, Alt+Tab, 복사/붙여넣기 등 자주 쓰는 단축키

레이어와 키 매핑에 대한 자세한 설명은 설정 파일 내 주석을 참고하세요.

### 설치 및 실행

1. `kanata/bin/disable_capslock.reg`를 적용하여 CapsLock을 F13으로 변환합니다 (Kanata가 CapsLock을 가로채려면 필요하며, 적용 후 재부팅이 필요합니다).
2. [`kanata/update_and_run.bat`](kanata/update_and_run.bat)을 실행합니다. 이 스크립트는 자기 자신을 최신 버전으로 갱신하고, CapsLock 레지스트리 설정을 확인하고, 최신 Kanata 바이너리와 설정 파일을 내려받은 뒤 트레이에서 Kanata를 실행합니다.
3. 설정을 되돌리려면 `kanata/bin/restore_capslock.reg`를 적용하세요.

### 로컬 테스트

설정 파일을 수정한 뒤 원격 다운로드 없이 바로 테스트하려면 [`kanata/run_local_test.bat`](kanata/run_local_test.bat)을 실행하세요. 실행 중인 Kanata 프로세스를 종료하고 로컬 `kanata/bin`의 바이너리와 설정으로 다시 시작합니다.
