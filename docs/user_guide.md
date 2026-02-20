# 로컬 개발 환경 구축 가이드

## 사전 요구사항

| 도구 | 버전 | 설치 확인 |
|------|------|-----------|
| Docker | 20.10+ | `docker --version` |
| Kind | 0.20+ | `kind --version` |
| Terraform | 1.0+ | `terraform --version` |
| kubectl | 1.27+ | `kubectl version --client` |
| Helm | 3.12+ | `helm version` |
| Git | 2.30+ | `git --version` |

## 1. 초기 설정 (최초 1회)

### 1-1. 레포지토리 클론

```bash
git clone https://github.com/MZC-Final-Project/mzc-final-project-infra.git
cd mzc-final-project-infra
```

### 1-2. Terraform 변수 파일 생성

```bash
cat > environments/local/terraform.tfvars <<'EOF'
github_username = "본인_GitHub_아이디"
github_token    = "본인_GitHub_PAT"
cluster_name    = "local-dev"
EOF
```

> GitHub PAT는 `repo` 권한이 필요합니다.
> Settings > Developer settings > Personal access tokens에서 생성합니다.

### 1-3. Jenkins 환경변수 파일 생성

```bash
cat > jenkins/.env <<'EOF'
GITHUB_USERNAME=본인_GitHub_아이디
GITHUB_TOKEN=본인_GitHub_PAT

GITHUB_INFRA_REPO_URL=https://github.com/MZC-Final-Project/mzc-final-project-infra.git
GITHUB_BE_REPO_URL=https://github.com/MZC-Final-Project/mzc-final-project-be.git
GITHUB_FE_REPO_URL=https://github.com/MZC-Final-Project/mzc-final-project-fe
EOF
```

### 1-4. Jenkins Docker 이미지 빌드

```bash
cd jenkins
docker compose build
cd ..
```

## 2. 환경 실행

### 2-1. Terraform 초기화 및 적용

```bash
cd environments/local
terraform init
terraform apply
```

이 명령 하나로 아래가 모두 자동 생성됩니다:

- Kind 클러스터 (control-plane + worker 노드)
- MetalLB (로드밸런서)
- Local Path Provisioner (스토리지)
- ArgoCD (GitOps CD)
- app-secret (서비스 크리덴셜)
- Jenkins + Registry 컨테이너 (Kind 네트워크 연결)

### 2-2. 배포 확인

```bash
# ArgoCD가 Helm 차트를 자동 배포합니다 (1~2분 소요)
kubectl get pods -n dev

# 모든 Pod가 Running이 될 때까지 대기
kubectl get pods -n dev -w
```

## 3. 접속 정보

| 서비스 | URL | 비고 |
|--------|-----|------|
| Frontend | http://localhost:3000 | React 앱 (Nginx) |
| Gateway API | http://localhost:8443 | Spring Cloud Gateway |
| Keycloak | http://localhost:9090 | admin / admin |
| ArgoCD | http://localhost:8080 | 아래 명령으로 비밀번호 확인 |
| Jenkins | http://localhost:8000 | admin / admin |
| MinIO Console | https://localhost:9001 | minioadmin / minioadmin1234 |
| MinIO API | https://localhost:9000 | S3 호환 API |

### ArgoCD 비밀번호 확인

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 4. CI/CD 파이프라인 흐름

### BE (백엔드)

```
BE repo develop 머지
  → Jenkins가 1분 내 감지 (SCM 폴링)
  → 변경된 서비스만 Docker 빌드 & Registry Push
  → infra repo의 values.yaml에서 해당 서비스 이미지 태그 업데이트
  → ArgoCD가 변경 감지 → 해당 서비스만 재배포
```

- 서비스 디렉토리(`domain/auth/gateway-service/` 등)만 변경 → 해당 서비스만 빌드
- 공통 모듈(`common/`)이나 `build.gradle` 변경 → 전체 서비스 빌드

### FE (프론트엔드)

```
FE repo develop 머지
  → Jenkins가 1분 내 감지
  → npm build → Nginx Docker 이미지 → Registry Push
  → infra repo의 values.yaml에서 feImageTag 업데이트
  → ArgoCD가 변경 감지 → Frontend 재배포
```

## 5. 주요 디렉토리 구조

```
mzc-final-project-infra/
├── environments/local/
│   ├── main.tf              # Kind 클러스터 + 인프라 정의
│   ├── argocd.tf            # ArgoCD 설정
│   ├── variables.tf         # 변수 정의
│   ├── terraform.tfvars     # 변수 값 (gitignored)
│   └── scripts/             # 로컬 배포 스크립트
├── charts/ticket-service/
│   ├── Chart.yaml           # Helm 차트 메타데이터
│   ├── values.yaml          # 이미지 태그 (Jenkins가 자동 업데이트)
│   └── templates/           # K8s 매니페스트 템플릿
│       ├── secret.yaml          # app-secret (gitignored)
│       ├── secret.example.yaml  # secret 예시 파일
│       ├── gateway-service.yaml
│       ├── frontend-service.yaml
│       └── ...
├── jenkins/
│   ├── Dockerfile           # Jenkins 이미지 정의
│   ├── docker-compose.yml   # Jenkins + Registry 실행
│   ├── .env                 # 환경변수 (gitignored)
│   ├── casc/jenkins.yaml    # Jenkins 설정 (JCasC)
│   └── pipelines/           # 파이프라인 정의 (레거시, 참조용)
└── docs/
    └── user_guide.md        # 이 문서
```

## 6. 자주 쓰는 명령어

```bash
# Pod 상태 확인
kubectl get pods -n dev

# 서비스 로그 확인
kubectl -n dev logs -f deploy/gateway-service

# Pod 재시작
kubectl -n dev rollout restart deploy/gateway-service

# ArgoCD 수동 동기화
kubectl -n argocd get application    # 상태 확인

# Helm 차트 렌더링 확인 (로컬)
helm template charts/ticket-service/

# Jenkins 로그 확인
docker logs -f jenkins
```

## 7. 환경 정리 및 재생성

### 전체 삭제

```bash
cd environments/local
terraform destroy
```

### 재생성

```bash
cd environments/local
terraform apply
# 끝. 모든 것이 자동으로 생성됩니다.
```

## 8. 트러블슈팅

### Pod가 CreateContainerConfigError 상태

```bash
kubectl -n dev describe pod <pod-name>
```

`secret "app-secret" not found` 에러인 경우 → `terraform apply`가 정상 완료되었는지 확인

### Jenkins 파이프라인이 안 돌 때

1. Jenkins 접속 (http://localhost:8000)하여 파이프라인 상태 확인
2. SCM 폴링이 1분 간격이므로 최대 1분 대기
3. `docker logs jenkins`로 에러 확인

### Frontend ImagePullBackOff

FE 이미지가 아직 빌드되지 않은 상태입니다. FE repo에 develop 머지를 하면 Jenkins가 자동으로 빌드합니다.

### MinIO ContainerCreating 지속

`minio-tls` secret이 생성되지 않은 경우입니다. Helm 차트에서 자동 생성되므로 ArgoCD 동기화가 완료될 때까지 기다립니다.
