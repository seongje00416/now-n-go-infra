> 본 레포지토리는 팀 프로젝트 Now&Go의 인프라 레포를 개인 포트폴리오 목적으로 fork한 것입니다.
> 원본: [MZC-Final-Project](https://github.com/MZC-Final-Project/mzc-final-project-infra)

# Now&Go 인프라 레포지토리

AI 기반 여행 플랜 원스톱 서비스 플랫폼 **Now&Go**의 클라우드 인프라 IaC(Infrastructure as Code) 레포지토리입니다.  
Terraform을 사용해 로컬 개발 환경부터 프로덕션 EKS 환경까지 전체 인프라를 코드로 관리합니다.

## 기술 스택

| 분야 | 기술 |
|:---:|:---:|
| 컨테이너 | Docker |
| 오케스트레이션 | Kubernetes (EKS / kind) |
| IaC | Terraform |
| CI | GitHub Actions |
| CD | ArgoCD |
| 컨테이너 레지스트리 | AWS ECR |
| 네트워크 | AWS VPC, NLB, NGINX Ingress |
| 데이터베이스 | AWS RDS (PostgreSQL 16) |
| 스토리지 | AWS S3 |
| 보안 | AWS IAM, IRSA, Secrets Manager |
| 모니터링 | AWS CloudWatch, SNS |

---

## 아키텍처

### 프로덕션 환경 전체 구성도

```
인터넷
  │
  ▼
NLB (AWS Network Load Balancer)
  │
  ▼
NGINX Ingress Controller (ingress-nginx namespace)
  │
  ▼
EKS 클러스터 (ap-northeast-2)
  ├── prod namespace
  │   └── 마이크로서비스 Pod들 (ArgoCD가 자동 배포/동기화)
  │
  ├── argocd namespace
  │   └── ArgoCD (mzc-final-project-argo 레포 감지 → 자동 배포)
  │
  └── ingress-nginx namespace
      └── NGINX Ingress Controller
  │
  ├── VPC (10.0.0.0/16)
  │   ├── Public Subnet (10.0.0.0/24, 10.0.1.0/24) — NLB, NAT GW
  │   └── Private Subnet (10.0.10.0/24, 10.0.11.0/24) — EKS 노드, RDS
  │
  ├── AWS RDS (PostgreSQL 16, db.t3.micro, Private Subnet)
  └── AWS S3 (미디어 파일 저장, AES-256 암호화, 버전 관리)
```

### 네트워크 흐름

```
클라이언트 요청
  → NLB (퍼블릭 서브넷, L4)
  → NGINX Ingress Controller (클러스터 내부)
  → gateway-service
  → 각 마이크로서비스 (프라이빗 서브넷 노드에서 실행)
  → RDS / S3 (프라이빗 서브넷, 외부 직접 접근 불가)
```

### CI/CD 파이프라인

```
개발자 코드 Push (mzc-final-project-be)
  │
  ▼
GitHub Actions (CI)
  ├── 코드 빌드 및 테스트
  ├── Docker 이미지 빌드
  └── ECR 푸시 + Argo 레포 이미지 태그 업데이트 (commit SHA)
  │
  ▼
ArgoCD (CD)
  ├── mzc-final-project-argo 레포 변경 감지 (selfHeal: true)
  └── EKS prod 네임스페이스에 자동 배포
```

---

## 레포지토리 구조

```
mzc-final-project-infra/
├── environments/
│   ├── local/              # kind 기반 로컬 개발 환경
│   │   ├── main.tf         # kind 클러스터 + MetalLB + ArgoCD 구성
│   │   ├── argocd.tf       # ArgoCD Helm 설치 및 앱 등록
│   │   ├── manifests/      # 로컬 서비스 Kubernetes 매니페스트
│   │   └── scripts/        # 로컬 배포 자동화 스크립트
│   │
│   ├── production/         # AWS EKS 프로덕션 환경
│   │   ├── vpc.tf          # VPC, 서브넷, IGW, NAT GW, 라우팅 테이블
│   │   ├── eks.tf          # EKS 클러스터, 노드 그룹, 애드온
│   │   ├── iam.tf          # IAM 역할, IRSA (OIDC Provider)
│   │   ├── rds.tf          # RDS PostgreSQL 인스턴스
│   │   ├── s3.tf           # S3 버킷 (암호화, 버전관리)
│   │   ├── argocd.tf       # ArgoCD Helm 설치 및 앱 등록
│   │   ├── ingress.tf      # NGINX Ingress Controller (NLB 연동)
│   │   └── k8s-config.tf   # Kubernetes 리소스 설정
│   │
│   └── integration/        # 통합 테스트 환경 (미완성)
│
├── ecs/                    # ECS 기반 대안 아키텍처 (탐색용)
│   └── modules/            # 재사용 가능한 Terraform 모듈
│       ├── alb/            # Application Load Balancer
│       ├── ecs-cluster/    # ECS 클러스터
│       ├── ecs-service/    # ECS 서비스
│       ├── rds/            # RDS 인스턴스
│       ├── elasticache/    # ElastiCache (Redis)
│       ├── iam/            # IAM 역할 및 정책
│       ├── monitoring/     # CloudWatch 알람, 대시보드, SNS
│       ├── secrets/        # Secrets Manager
│       ├── security-groups/# 보안 그룹
│       └── vpc/            # VPC 및 네트워킹
│
├── ecr/                    # ECR 레지스트리 독립 관리
├── service/kafka/          # Kafka 커스텀 Helm Chart
└── docs/                   # 환경별 설정 가이드 문서
```

---

## 주요 설계 결정

### 1. EKS를 선택한 이유

마이크로서비스 아키텍처로 약 48개의 서비스를 운영해야 하는 상황에서 컨테이너 오케스트레이션 도구가 필요했습니다.

| | ECS | EKS |
|--|--|--|
| 학습 비용 | 낮음 | 높음 |
| 오토스케일링 | 제한적 | HPA / Cluster Autoscaler |
| 서비스 디스커버리 | ALB 의존 | 클러스터 내부 DNS |
| 이식성 | AWS 종속 | 클라우드 무관 |
| 생태계 | 제한적 | CNCF 전체 |

서비스 수가 많고 향후 멀티클라우드 전환 가능성을 고려해 **EKS**를 선택했습니다. ArgoCD, NGINX Ingress 등 CNCF 생태계 도구를 자유롭게 활용할 수 있다는 점도 결정적인 이유였습니다.

### 2. Terraform으로 전체 인프라를 코드로 관리한 이유

초기에는 콘솔에서 수동으로 인프라를 구성했으나 아래 문제가 반복됐습니다.

- 로컬 환경과 배포 환경 간 인프라 불일치로 인한 배포 실패
- 팀원이 인프라 설정을 공유하기 어려움
- 테스트 후 리소스 삭제 및 재생성이 번거로움

Terraform 도입 후 `terraform apply` 한 번으로 전체 인프라가 동일하게 재현되면서 **배포 환경 구축 시간이 약 2시간에서 15분으로 단축**됐습니다.

### 3. IRSA(IAM Roles for Service Accounts)를 적용한 이유

초기에는 정적 Access Key 방식으로 Pod에서 AWS 서비스에 접근했습니다.

```
문제: 정적 키가 Kubernetes Secret에 저장 → 키 노출 시 전체 권한 탈취 위험
      키 로테이션이 수동 작업
```

IRSA를 적용해 OIDC Provider를 통해 특정 ServiceAccount에만 IAM 역할을 부여했습니다.

```hcl
# ebs-csi-controller-sa 에만 AssumeRole 허용
Condition = {
  StringEquals = {
    "${oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  }
}
```

정적 키 없이 Pod가 AWS 서비스에 접근할 수 있어 보안이 강화됐습니다. S3 접근용 IAM 유저는 현재 정적 키 방식으로 남아있으며 IRSA 전환이 개선 과제입니다.

### 4. 로컬/프로덕션 환경을 분리한 이유

```
environments/local/      → kind (Kubernetes IN Docker)
environments/production/ → AWS EKS
```

- **로컬**: Docker Desktop만 있으면 실행 가능, AWS 비용 없음, 빠른 이터레이션
- **프로덕션**: 실제 AWS 인프라, 고가용성 구성

두 환경이 동일한 Kubernetes 매니페스트를 사용하므로 로컬에서 검증된 설정이 프로덕션에서도 동일하게 동작합니다.

### 5. ArgoCD GitOps 방식을 선택한 이유

```
기존 방식: CI에서 직접 kubectl apply → 배포 이력 추적 어려움
GitOps 방식: Git이 단일 진실의 원천 → 변경 이력 = Git 커밋 이력
```

`selfHeal: true` 설정으로 누군가 클러스터를 직접 수정해도 Git 상태로 자동 복구됩니다. 팀 협업 환경에서 의도치 않은 클러스터 상태 변경을 방지하기 위해 선택했습니다.

---

## 모니터링 구성

CloudWatch 기반 모니터링을 Terraform으로 코드화했습니다.

| 알람 | 조건 | 알림 |
|------|------|------|
| ALB 5xx 오류율 | 1분 내 5건 초과 | SNS → 이메일 |
| ALB 응답 시간 | 평균 5초 초과 | SNS → 이메일 |

CloudWatch 대시보드에서 ECS CPU/메모리 사용률, ALB 요청 수, RDS CPU 사용률을 한눈에 확인할 수 있도록 구성했습니다.

---

## 트러블슈팅 경험

### 1. EKS 노드 그룹 생성 후 애드온 설치 순서 문제

**문제**: `terraform apply` 한 번으로 전체 인프라를 구성하려 했으나, EBS CSI Driver 애드온이 노드 그룹보다 먼저 설치되려 해서 실패했습니다.

**원인**: Terraform이 리소스 간 의존성을 자동으로 파악하지 못하는 경우가 있습니다. 애드온은 노드 그룹이 준비된 후에 설치되어야 합니다.

**해결**: `depends_on`을 명시적으로 추가했습니다.

```hcl
resource "aws_eks_addon" "ebs_csi_driver" {
  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver,
  ]
}
```

**재발 방지**: 이후 모든 EKS 애드온에 `depends_on = [aws_eks_node_group.main]` 을 명시하는 컨벤션을 팀 내에서 공유했습니다.

---

### 2. NGINX Ingress Controller NLB 프로비저닝 지연

**문제**: `terraform apply` 완료 후 `gateway_service_url` output이 비어있어 서비스 접근이 불가했습니다.

**원인**: AWS NLB 프로비저닝에는 실제로 수 분이 소요되는데, Terraform은 Helm 배포 완료만 확인하고 output을 반환하기 때문입니다.

**해결**: output에 NLB가 아직 준비 중임을 알리는 fallback 메시지를 추가하고, 팀원들에게 배포 후 5분 대기 후 `terraform output`으로 재확인하도록 가이드했습니다.

```hcl
output "gateway_service_url" {
  value = try(
    "http://${data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname}",
    "NLB 프로비저닝 중 - 잠시 후 'terraform output gateway_service_url' 로 재확인하세요"
  )
}
```

---

### 3. kind 로컬 환경에서 MinIO TLS 인증서 문제

**문제**: Spring Boot 서비스가 MinIO(S3 호환 오브젝트 스토리지)에 접근할 때 TLS 인증서 검증 실패로 연결이 안 됐습니다.

**원인**: 로컬 환경에서 자체 서명 인증서(self-signed certificate)를 사용했는데, JVM이 이를 신뢰하지 않았습니다.

**해결**: MinIO 인증서를 자동 생성하고 macOS 키체인에 등록하는 스크립트를 작성했습니다. WSL 환경에서는 `/etc/ssl/certs`에 인증서를 추가했습니다.

---

## 개선 예정 사항

- [ ] S3 접근용 IAM 유저 정적 키 방식 → **IRSA 전환**
- [ ] HPA(Horizontal Pod Autoscaler) 추가 — 트래픽 기반 Pod 자동 스케일링
- [ ] Cluster Autoscaler 추가 — 노드 자동 스케일링으로 비용 최적화
- [ ] Spot Instance 도입으로 워커 노드 비용 절감
- [ ] Terraform Remote State — S3 backend + DynamoDB lock으로 팀 협업 시 state 충돌 방지
- [ ] Prometheus + Grafana 도입 — CloudWatch 외 오픈소스 모니터링 스택 추가

---

## 로컬 환경 빠른 시작

### 사전 요구사항
- Docker Desktop 설치 및 실행
- Terraform >= 1.0
- kubectl
- kind

### 설치 (WSL / macOS)

```bash
# kind 설치 (Linux/WSL)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Terraform 설치
sudo apt update && sudo apt install -y terraform

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl
```

### 로컬 클러스터 실행

```bash
cd environments/local

# 1. 설정 파일 복사
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars에 GitHub username과 PAT 입력

# 2. 인프라 구성 (kind 클러스터 + ArgoCD)
terraform init
terraform apply

# 3. kubeconfig 설정
kind export kubeconfig --name local-dev

# 4. 클러스터 확인
kubectl get pods -A
```

### 서비스 배포

```bash
# 전체 배포 (Java 빌드 + Docker 이미지 + 서비스 배포)
./scripts/deploy-local.sh

# 경량 배포 (RAM 8GB 이하 환경, 브로커 서비스 제외)
./scripts/deploy-local.sh --light

# 상태 확인
./scripts/deploy-local.sh --status
```

---

## 프로덕션 배포

```bash
cd environments/production

cp terraform.tfvars.example terraform.tfvars
# DB 패스워드, GitHub 토큰 등 입력

terraform init
terraform apply

# kubectl 컨텍스트 연결
aws eks update-kubeconfig --region ap-northeast-2 --name <cluster_name>

# 배포 확인
kubectl get pods -n prod
kubectl get svc -n ingress-nginx
```

> NLB 프로비저닝에 수 분이 소요됩니다. 완료 후 `terraform output gateway_service_url`로 접속 URL을 확인하세요.