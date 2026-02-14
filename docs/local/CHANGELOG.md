# Local 환경 변경 이력

## 2025-02-14 MinIO (S3 호환 오브젝트 스토리지) 추가

### 배경
백엔드 user-command-service에서 파일/이미지 업로드 기능을 위해 AWS S3가 필요.
로컬 환경에서는 S3 호환 API를 제공하는 MinIO를 배포하여 대체.

### 변경 파일

| 파일 | 변경 유형 | 내용 |
|------|-----------|------|
| `manifests/dev/minio.yaml` | 신규 | MinIO Deployment, NodePort Service, 버킷 생성 Job |
| `manifests/dev/configmap.yaml` | 수정 | S3_ENDPOINT, S3_REGION, S3_BUCKET 추가 |
| `manifests/dev/secret.yaml` | 수정 | S3_ACCESS_KEY, S3_SECRET_KEY 추가 |
| `manifests/dev/user-command-service.yaml` | 수정 | S3 환경변수 5개 주입 |
| `main.tf` | 수정 | Kind 포트 매핑 추가 (30100→9000, 30101→9001) |
| `scripts/deploy-local.sh` | 수정 | MinIO 배포 단계, 메모리 요약, 접속 정보 추가 |

### MinIO 구성

- 이미지: `minio/minio:RELEASE.2024-06-13T22-53-53Z`
- 모드: Standalone (단일 인스턴스)
- 볼륨: emptyDir (Pod 재시작 시 데이터 초기화)
- 리소스: 128Mi/256Mi (requests/limits)
- 기본 버킷: `user-profiles` (Job으로 자동 생성)

### 접속 정보

| 서비스 | URL | NodePort |
|--------|-----|----------|
| S3 API | http://localhost:9000 | 30100 |
| MinIO Console (Web UI) | http://localhost:9001 | 30101 |

- 로그인: `minioadmin` / `minioadmin1234`

> Kind 포트 매핑(main.tf)은 클러스터 재생성 시 적용됨. 기존 클러스터에서는 port-forward 사용:
> ```bash
> kubectl -n dev port-forward svc/minio 9000:9000 9001:9001
> ```

### 환경변수 (user-command-service)

| 변수 | 소스 | 값 |
|------|------|----|
| S3_ENDPOINT | ConfigMap | http://minio:9000 |
| S3_REGION | ConfigMap | us-east-1 |
| S3_BUCKET | ConfigMap | user-profiles |
| S3_ACCESS_KEY | Secret | minioadmin |
| S3_SECRET_KEY | Secret | minioadmin1234 |

### 백엔드 연동 가이드

user-command-service에서 S3를 사용하려면:

1. **의존성 추가** (`build.gradle`)
   ```groovy
   implementation 'software.amazon.awssdk:s3:2.25.x'
   ```

2. **application.yml 설정**
   ```yaml
   s3:
     endpoint: ${S3_ENDPOINT:http://localhost:9000}
     region: ${S3_REGION:us-east-1}
     bucket: ${S3_BUCKET:user-profiles}
     access-key: ${S3_ACCESS_KEY:minioadmin}
     secret-key: ${S3_SECRET_KEY:minioadmin1234}
   ```

3. **S3Client 빈 생성 시 주의사항**
   ```java
   S3Client.builder()
       .endpointOverride(URI.create(endpoint))
       .region(Region.of(region))
       .credentialsProvider(StaticCredentialsProvider.create(
           AwsBasicCredentials.create(accessKey, secretKey)))
       .forcePathStyleAccess(true)  // MinIO 필수
       .build();
   ```

---

## 2025-02-14 Kafka / Keycloak 안정성 개선

### 변경 파일

| 파일 | 내용 |
|------|------|
| `manifests/dev/kafka.yaml` | KAFKA_HEAP_OPTS 추가 (-Xms128m -Xmx256m), OOM 방지 |
| `manifests/dev/kafka-business.yaml` | KAFKA_HEAP_OPTS 추가, readiness probe를 tcpSocket으로 변경, CONTROLLER_QUORUM_VOTERS를 localhost로 변경 |
| `manifests/dev/keycloak.yaml` | startupProbe 추가 (최대 330초 대기), liveness/readiness에서 initialDelaySeconds 제거 |
| `scripts/deploy-local.sh` | deploy_apps()에 rollout restart 추가 (동일 태그 이미지 갱신용) |

### 문제 및 해결

**Kafka OOMKilled**
- 원인: JVM 기본 힙이 컨테이너 메모리 limit(512Mi)를 초과
- 해결: `KAFKA_HEAP_OPTS: "-Xms128m -Xmx256m"`으로 힙 제한

**Kafka-business readiness probe 타임아웃**
- 원인: `kafka-broker-api-versions.sh`가 별도 JVM을 띄워 메모리 부족 + 5초 타임아웃 초과
- 해결: tcpSocket probe (port 9092)로 변경

**Keycloak CrashLoopBackOff**
- 원인: Quarkus augmentation(55초) + Infinispan 초기화로 liveness probe initialDelaySeconds(90초) 초과
- 해결: startupProbe 추가 (30초 후 10초 간격, 최대 30회 = 330초 대기)

**앱 재배포 시 이미지 미반영**
- 원인: 이미지 태그가 동일(`:local`)하여 kubectl apply가 변경 감지 못함
- 해결: deploy_apps()에 `kubectl rollout restart` 추가

---

## 2025-02-14 암호화 키 환경변수 추가

### 변경 파일

| 파일 | 내용 |
|------|------|
| `manifests/dev/secret.yaml` | ENCRYPTION_AES_KEY, ENCRYPTION_HMAC_KEY 추가 |
| `manifests/dev/user-command-service.yaml` | 암호화 키 환경변수 2개 주입 |

---

## 2025-02-14 ArgoCD NodePort 충돌 해결

### 변경 파일

| 파일 | 내용 |
|------|------|
| `argocd.tf` | ArgoCD HTTP NodePort를 30070으로 고정 (gateway-service 30080과 충돌 방지) |

### 포트 할당 현황

| 서비스 | NodePort | Host Port |
|--------|----------|-----------|
| Gateway Service | 30080 | 8080 |
| ArgoCD | 30070 | - |
| Keycloak | 30090 | 9090 |
| MinIO S3 API | 30100 | 9000 |
| MinIO Console | 30101 | 9001 |
