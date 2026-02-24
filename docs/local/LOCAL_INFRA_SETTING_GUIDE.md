# 로컬 환경 인프라 구축
- 로컬 환경에서 개발 후 다른 서비스와의 연결을 테스트할 수 있는 로컬 테스트 환경을 위한 인프라입니다.
- 로컬 인프라에 기본으로 구축되는 서비스는 다음과 같습니다.
1. Kind 클러스터 ( K8S 클러스터 )
2. ArgoCD
3. Kakfa
4. Redis
5. Common Services
    - gateway-service : BE 게이트웨이
    - email-service : 이메일 서비스
    - user-command-service
    - user-query-service
    - minio : 로컬 스토리지
## 로컬 인프라 구축 과정
1. 로컬 작업을 위한 라이브러리 설치
    - kind, terraform, kubectl 설치가 필요합니다.
2. Terraform을 통한 인프라 구축
    - kind 클러스터 및 ArgoCD, Auth Service, Redis 등 대부분의 인프라는 Terraform을 통해 구축됩니다.
3. 서비스 모듈 배포
    - Kafka의 경우 추가 작업을 통해 배포가 필요합니다.

### 0. 기본 파일 준비
- infra/environment/local 경로에 아래 파일이 존재하는지 확인합니다.
    1. main.tf
    2. varlues.tf
    3. outputs.tf
    4. redis.tf
    5. argocd.tf
    6. manifests/ci
    7. manifests/dev
    8. terraform.tfvars
- terraform.tfvars의 경우, 민감한 정보가 기록된 파일이므로 로컬에서 작성이 필요합니다.
    - terraform.tfvars.example 파일을 참고해 작성합니다.
    - github_username과 github_token만 자신의 값에 맞게 수정합니다.
- redis_password는 로컬 Redis에서 사용할 비밀번호 입니다. 자유롭게 지정해주셔도 됩니다. ( 추후 redis 모듈의 application.yml에 작성해주어야 하니 기억해둡시다. )

### 1. 로컬 작업을 위한 라이브러리 설치
```
# Linux 환경 ( WSL )

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

# 4. Helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 5. 설치 확인
kind --version
terraform --version
kubectl version --client
helm version
```
```
# MacOS 환경

# Homebrew 설치 (없다면)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 1. Kind 설치
brew install kind

# 2. Terraform 설치
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# 3. kubectl 설치
brew install kubectl

# 4. Helm 설치
brew install helm

# 설치 확인
kind --version
terraform --version
kubectl version --client
helm version
```
- kind: 로컬 클러스터 구축을 위해 필요한 패키지
- terraform: IaC를 위한 패키지
- kubectl: K8S 명령어 사용을 위한 패키지
- helm: Helm Chart를 사용해 배포를 하기 위한 패키지

### 2. Terraform을 통한 인프라 구축
##### 로컬 클러스터 구축을 위한 Terraform 파일이 정의되어 있는 경로로 이동
> /mzc-final-project-infra/environments/local
- pwd 명령어 입력해 해당 디렉토리가 나오는지 확인
##### Terraform 실행
```
# Terraform 초기화
terraform init

# Terraform 파일이 정상적인지 확인
terraform plan

# Terraform 파일을 통한 인프라 구축
terraform apply
```
- 구축 과정에서 에러가 난다면 어떤 에러인지 확인하기
###### 현재 확인된 에러
<table>
    <thead>
        <tr>
            <td> 에러명 </td>
            <td> 해결 방법 </td>
        </tr>
    </thead>
    <tr>
        <td> 없음 </td>
        <td></td>
    </tr>
</table>

##### 구축 확인
```
# kind 클러스터 구축 확인
kind get clusters
```
- local-dev 라는 이름의 클러스터가 생성되어 있으면 완료
```
# 현재 실행 중인 노드 확인
kubectl get nodes
```
- control-plane 1개와 worker 2개가 생성되어 있으면 완료
- 세 개의 노드의 STATUS가 모두 Ready인지 확인
```
# 현재 실행 중인 파드 확인
kubectl get pods -n dev
kubectl get pods -n redis
kubectl get pods -n argocd
```
- redis의 경우 1개의 Pod가 Running 상태이면 완료
- argocd의 경우 모든 Pod가 Running 상태이면 완료
- dev의 경우 Pod들이 정상적으로 Running 상태이면 완료

##### ArgoCD 접속 확인
```
# ArgoCD 접속 비밀번호 확인 ( username은 admin )
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# ArgoCD 접속
# 포트포워딩 설정
kubectl port-forward svc/argocd-server -n argocd 8080:443

# NodePort 확인 -> http://localhost:확인된 노드 포트
kubectl get svc -n argocd argocd-server
```
- 위 작업이 완료되면 로컬의 브라우저에서 localhost:8080을 통해 ArgoCD UI로 접근 가능

### 3. Kafka 서비스 배포
- Kafka의 경우, 이미지를 다운로드할 수 있는 레포지토리의 제한과 많은 설정 값으로 인해 따로 배포가 필요
##### 아래 경로로 이동
> /mzc-final-project-infra/service/kafka
- Git의 Infra 레포지토리에 service 경로가 존재
- pwd 명령어를 입력했을 때 이 경로가 나오도록 설정
##### 스크립트 실행
```
./deploy-kafka.sh
```
*주의: deploy-kafka.sh를 실행해야 합니다. deploy-entrypoint.sh를 실행하면 안됩니다.*
- 해당 스크립트 파일은 Dockerfile 빌드부터 로컬 클러스터에 배포까지 진행합니다.
- 로컬 클러스터가 구축되어 있다는 전제하에 만들어진 스크립트 파일입니다. 반드시 선행 작업을 완료하고 진행해주세요.
##### 배포 확인
```
kubectl get pods -n kafka
```
- 명령어를 실행했을 때 kafka Pod가 1개 실행 중이고 STATUS가 Running면 완료
##### Trouble-Shooting
- 해당 스크립트 파일을 실행하다 에러가 나거나 실수했을 경우 아래 명령어를 통해 빌드 및 배포를 초기화하고 진행합니다.
```
helm uninstall kafka -n kafka
```
### 4. ArgoCD를 통한 클러스터 동기화
(작업중)

## 배포 환경 상세 설명
### 클러스터
#### 네임스페이스 전략
| 네임스페이스명 | 역할 |
| :---: | :---: |
| dev | 마이크로 서비스들이 배포되는 네임스페이스입니다. |
| argocd | ArgoCD가 작동하는 네임스페이스입니다. |
| redis | 공용 Redis 서비스가 작동하는 네임스페이스입니다. |
| kafka | 공용 Kafka 서비스가 작동하는 네임스페이스입니다. |

#### 서비스 경로
- 개발해서 배포하는 모든 서비스는 dev 네임스페이스에 배포되어야 합니다.
- 일부 공통 모듈 외 모든 서비스는 dev 네임스페이스에 배포되기 때문에 호출시 다음과 같은 엔드포인트로 호출할 수 있습니다.
```
서비스명:포트번호
ex) user-command-service:8086
```
- 공용 Kafka, Redis의 경우 별도의 네임스페이스를 사용하기 때문에 FQDN을 사용합니다.
- FQDN의 기본적인 형태는 다음과 같습니다.
```
서비스명.네임스페이스.svc.cluster.local:포트번호
```
- 현재 로컬 클러스터에서 사용할 수 있는 FQDN은 다음과 같습니다.
| 서비스명 | FQDN |
| :---: | :---: |
| Redis | redis-master.redis.svc.cluster.local:6379 |
| Kafka | kafka.kafka.svc.cluster.local:9092 |



