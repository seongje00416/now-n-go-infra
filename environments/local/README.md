### 로컬 클러스터 개발 환경 구축

#### 개요
k8s는 기본적으로 클러스터가 구축되어 있어야 작동함을 확인할 수 있기 때문에 인프라 내에서 정상적으로 작동하는지 확인을 위해선 로컬에 클러스터를 구축하는 것이 필요함.

#### 구축 방법
##### 0. 개요
- 작업은 관리자 권한이 있는 Shell에서 진행되어야 한다

##### 1. kind를 통한 클러스터 설치 ( Kubernets IN Docker )
- Docker를 통해 k8s 환경을 구축할 수 있도록 해주는 도구
- 로컬에서 Docker 사용을 위해 Docker Desktop 활용( 설치 필수 )

###### Windows WSL 환경
```bash
# WSL 터미널에서 실행

# 1. Kind 설치
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# 2. Terraform 설치
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# 3. kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# 설치 확인
kind --version
terraform --version
kubectl version --client
```

> **WSL Docker Desktop 설정**: 별도 설정 없이 Windows에서 Docker Desktop GUI를 실행하면  
> WSL 내 `docker` 명령어가 자동으로 Docker Desktop에 연결됩니다.  
> 자세한 내용은 [DOCKER_DESKTOP_GUIDE.md](DOCKER_DESKTOP_GUIDE.md)를 참고하세요.

###### Windows 환경
```
# 관리자 권한으로 PowerShell 실행

# 1. Chocolatey 설치 (패키지 매니저, 없다면)
$ Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Kind 설치
$ choco install kind -y

# 3. Terraform 설치
$ choco install terraform -y

# 4. kubectl 설치
$ choco install kubernetes-cli -y

# 설치 확인
$ kind --version
$ terraform --version
$ kubectl version --client

# PowerShell 재시작 (PATH 업데이트)
```

###### Windows 환경 - 패키지 제거 (WSL로 전환 시)
WSL 환경을 사용하기로 결정한 경우, Windows 네이티브에 설치했던 패키지를 제거합니다.
```powershell
# 관리자 권한으로 PowerShell 실행

# 1. Kind 제거
choco uninstall kind -y

# 2. Terraform 제거
choco uninstall terraform -y

# 3. kubectl 제거
choco uninstall kubernetes-cli -y

# 제거 확인 (각 명령어가 'not recognized' 오류를 내면 정상 제거)
kind --version
terraform --version
kubectl version --client

# (선택) Chocolatey 자체도 제거하려면
# Remove-Item -Recurse -Force "$env:ChocolateyInstall"
# [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'Machine')
```
> **kubeconfig 정리** (필요한 경우):  
> Windows 네이티브에서 생성된 kubeconfig가 있다면 `C:\Users\<username>\.kube\config` 파일을 삭제하거나 백업하세요.

###### MacOS 환경
```
# Homebrew 설치 (없다면)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 1. Kind 설치
brew install kind

# 2. Terraform 설치
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# 3. kubectl 설치
brew install kubectl

# 설치 확인
kind --version
terraform --version
kubectl version --client
```
##### 유의할 점
1. Docker Desktop이 설치되어 있고 실행되고 있어야 함
   - **WSL**: Windows에서 Docker Desktop GUI를 실행하면 WSL 내 `docker` 명령어가 자동으로 Docker Desktop에 연결됨 (별도 context 설정 불필요)
2. kubeconfig 파일이 정확한 위치에 위치해야 함
( 생성은 kind가 자동으로 하고 일반적으로는 제 위치에 만들어주나 오류가 날 경우 확인 필요 )
   - Windows 네이티브: `C:\Users\<username>\.kube\config`
   - Mac / WSL: `~/.kube/config`
3. **WSL 환경 한정**: Docker Desktop 설치 후 KVM 그룹 추가 필수
   ```bash
   sudo usermod -aG kvm $USER
   # 이후 완전한 재로그인(GUI 세션 로그아웃/로그인) 필요
   ```

##### 2. Terraform 초기화 및 적용
```
# 해당 프로젝트 위치로 이동
$ cd mzc-final-project-infra/environments/local

# Terraform 초기화 및 실행
$ terraform init
$ terraform plan
$ terraform apply
```
###### 특징
- 작업이 완료되면 Docker Desktop에서 각 노드에 해당하는 Container가 실행 중인 것을 확인할 수 있음
##### 2-1. ArgoCD 구동 확인
```
# ArgoCD 비밀번호 확인

## Mac OS / WSL
$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
## Windows (PowerShell)
$ [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}')))

# ArgoCD 접속
# 포트포워딩 설정
## 아래 명령어를 그대로 입력하면 8080으로 포트포워딩
## 다른 포트로 포트포워딩 하고 싶으면 8080 숫자에 다른 포트를 입력할 것
kubectl port-forward svc/argocd-server -n argocd 8080:443

# NodePort 확인 -> http://localhost:확인된 노드 포트
$ kubectl get svc -n argocd argocd-server
```
###### 유의할 점
1. local 경로에서 실행해야 로컬용 클러스터를 구축하고 생성을 진행함
=> stage는 추후 EKS 배포용 코드
2. Github에서 최초 clone했을 때는 최상위 경로에 위치하기 때문에 꼭 cd를 통해 경로 이동 필요

##### 3. kubeconfig 설정
```
$ kind export kubeconfig --name local-dev
```

##### 4. 클러스터 구축 확인
```
# 클러스터 정보 출력
$ kubectl cluster-info

# 노드 목록 조회
$ kubectl get nodes

# 파드 목록 조회
$ kubectl get pods -A
```
##### 유의할 점
1. 노드 및 파드 목록은 개발 진행도에 따라 달라질 수 있음
2. 로컬 클러스터는 원격 클러스터와 완전히 별개이기 때문에 테스트 전 최신화 권장( 다른 서비스와 통신이 필요한 경우 )
3. 한 번 위 작업을 진행하면 이후 인프라가 업데이트 되지 않는 이상 다시 진행할 필요 없음
=> Docker Desktop에서 만들어진 컨테이너를 실행하면 바로 로컬 클러스터 실행 가능
    * 단, 클러스터 내 서비스들은 정기적인 최신화 필요
4. **WSL 환경 한정**: 클러스터 재사용 시 Docker Desktop GUI가 실행 중이어야 함
   - Docker Desktop이 꺼져 있으면 kind 클러스터 컨테이너가 있어도 접근 불가
   - 재시작 후 아래 명령어로 kubeconfig 재적용 필요할 수 있음
   ```bash
   kind export kubeconfig --name local-dev
   ```

#### 로컬 클러스터 서비스 최신화
- 개발이 완료된 기능 및 공용 모듈 서비스의 경우 로컬에서 테스트할 때 필요할 수 있음
- 그렇기 때문에 로컬 클러스터에 서비스 배포를 해야 하는 경우가 존재
- 우리는 배포에 ArgoCD를 사용하기 때문에 ArgoCD를 이용한 동기화 스크립트를 활용해 동기화를 진행
- 로컬에서 개발한 서비스와 다른 서비스와의 통신이 필요한 경우 로컬에 배포를 진행하며, 이 때는 '로컬 서비스 배포 스크립트'를 사용해 ArgoCD를 거치지 않고 로컬에만 배포해서 테스트 진행
###### 정리
1. 이미 PR이 완료되어 배포된 기능은 CI/CD를 통해 이미지가 컨테이너 레지스트리에 존재하고 ArgoCD가 이 정보를 알기 때문에 ArgoCD를 통해 원격 저장소에서 배포 받아 사용
=> 이를 위해 'remote-to-local-deployment.sh' 스크립트 사용
2. 아직 검증이 되지 않은 개발 단계의 개인 서비스는 ArgoCD에 배포하면 안되므로 로컬에서 바로 로컬 클러스터에 배포해서 사용
=> 이를 위해 'local-to-local-deployment.sh' 스크립트 사용