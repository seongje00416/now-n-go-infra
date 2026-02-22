# Docker Desktop 설치 가이드

## 개요
팀 프로젝트에서는 Kind(Kubernetes IN Docker)를 사용하며, Docker Desktop 위에서 동작합니다.  
기존에 Docker Engine이 설치되어 있는 경우에도 Docker Desktop과 **공존이 가능**합니다.

> **환경 참고**: 이 가이드는 **WSL(Windows Subsystem for Linux)** 환경을 기준으로 작성되었습니다.

---

## WSL 환경에서의 Docker Desktop 동작 방식

WSL에서는 Docker Desktop이 실행 중일 때 `/var/run/docker.sock`을 자동으로 점유합니다.

```
Docker Desktop GUI 실행
        ↓
/var/run/docker.sock 점유 (Docker Desktop daemon)
        ↓
docker 명령어 → 자동으로 Docker Desktop에 연결
```

따라서 **Docker Desktop GUI를 켜두기만 하면 별도의 context 설정 없이 어디서든 Docker Desktop이 사용됩니다.**

---

## 기존 Docker Engine이 설치되어 있는 경우

### 부작용
| 항목 | 내용 |
|------|------|
| 소켓 점유 전환 | Docker Desktop 실행 시 `/var/run/docker.sock`을 Docker Desktop이 점유하므로, 기존 Docker Engine 컨테이너가 보이지 않을 수 있음 |
| 기존 컨테이너 | Docker Desktop 실행 중에는 기존 Docker Engine에서 실행 중이던 컨테이너에 접근 불가 |

### 전환 방법
```bash
# Docker Desktop 사용: GUI 실행만 하면 자동 적용
# Docker Desktop 종료 시 기존 Docker Engine으로 자동 복귀

# 현재 연결된 daemon 확인
docker info | grep -E "Server Version|Operating System"
```

---

## 설치 순서

1. **기존 컨테이너 목록 기록**
   ```bash
   docker ps -a
   ```

2. **Docker Desktop 설치**
   - https://www.docker.com/products/docker-desktop/
   - Ubuntu: 아래 명령어로 설치
   ```bash
   wget -q https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -O /tmp/docker-desktop-amd64.deb
   sudo apt-get install -y /tmp/docker-desktop-amd64.deb
   ```

3. **KVM 그룹 추가 (Linux 필수)**
   ```bash
   sudo usermod -aG kvm $USER
   ```
   이후 **완전한 재로그인 필요** (터미널 재시작이 아닌 GUI 세션 로그아웃/로그인)

4. **설치 확인**
   ```bash
   # Docker Desktop GUI 실행 후
   docker run --rm hello-world
   # "Hello from Docker!" 출력되면 정상
   ```

---

## 참고
- WSL 환경에서는 `desktop-linux` context 사용 불가 (Windows 전용 named pipe 방식)
- Docker Desktop 실행/종료만으로 Docker Engine과 자동 전환되므로 **context 수동 전환 불필요**
- Docker Desktop을 설치해도 기존 Docker Engine을 **제거할 필요 없음**
- kubectl, terraform, kind 설치는 Docker Desktop 설치 전/후 상관없이 가능
