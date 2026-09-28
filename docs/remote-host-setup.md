# 원격 PC / 호스트 PC 동시 운영

이 repo는 호스트 PC와 원격(remote) PC 양쪽에서 각각 kanata를 실행하는 구조를 전제로 한다. 두 PC 모두 독립적으로 물리 키보드 입력을 받아 kanata를 돌리며, 이 repo를 각자 git clone해서 설정을 동기화한다.

## 배포 절차

각 PC(호스트, 원격 모두)에서 동일하게 수행한다.

1. `git pull`로 최신 설정을 받는다.
2. `deploy_kanata_cmd.bat`를 실행해 `bin\kanata.cmd`, `bin\kanata.kbd`, kanata 바이너리를 `%USERPROFILE%\bin`으로 복사한다.
3. 실행 중인 `kanata.cmd`를 재시작해 변경 사항을 적용한다.

`deploy_kanata_cmd.bat`는 `bin` 폴더 옆에서 고정된 per-user 위치로 배포하도록 설계되어 있으며, host/remote 구분 없이 동일한 스크립트를 쓴다.

## 주의사항

- 원격 데스크톱(RDP 등)으로 호스트 PC에 접속해서 작업 중이라면, 호스트 PC의 kanata와 원격 PC(로컬에서 RDP 클라이언트를 실행하는 PC)의 kanata가 동시에 떠 있을 수 있다. 두 kanata 인스턴스가 각자의 물리 키보드 입력을 처리하므로, 레이어 상태나 단축키 동작이 PC별로 독립적이라는 점을 감안해야 한다.
- 설정(`bin\kanata.kbd`)을 바꿀 때는 두 PC 모두에 배포해야 동작이 일치한다. 한쪽만 업데이트하면 PC 간 동작이 어긋난다.
- 소켓 기반 제어(`localhost:7070` 등, `docs/config.adoc` 참고)를 쓰는 스크립트는 PC별로 독립된 kanata 인스턴스에 연결되므로, 원격 PC에서 호스트 PC의 kanata 소켓을 직접 제어할 수는 없다.
