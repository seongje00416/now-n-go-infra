#!/bin/bash
# ==============================================================================
# deploy-local.sh - BE 서비스를 로컬 Kind 클러스터에 빌드 & 배포
#
# 사용법:
#   ./deploy-local.sh                    # 전체 배포 (인프라 + 브로커 + 앱)
#   ./deploy-local.sh --light            # 경량 배포 (브로커 스킵, 리소스 최소화)
#   ./deploy-local.sh --light --apps-only # 경량 모드로 앱만 재배포
#   ./deploy-local.sh --apps-only        # 앱 서비스만 재배포
#   ./deploy-local.sh --infra-only       # 인프라만 배포
#   ./deploy-local.sh --cleanup          # 전체 리소스 정리
#   ./deploy-local.sh --pause            # 모든 배포 컨테이너 일시 중지
#   ./deploy-local.sh --resume           # 일시 중지된 컨테이너 다시 시작
#   ./deploy-local.sh --status           # 현재 상태 확인
#
# 경량 모드 (--light): RAM 16GB 이하 Mac 권장
#   - Broker 인프라 스킵 (kafka-business, redis-business, postgres-booking)
#   - 리소스 설정은 매니페스트에 직접 반영됨 (별도 패치 없음)
#   - 예상 메모리: ~2.4GB (limits 합계)
# ==============================================================================

set -euo pipefail

# ── 경로 설정 ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_LOCAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFESTS_DIR="$INFRA_LOCAL_DIR/manifests/dev"

BE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../../../../mzc-final-project-be" && pwd)"
BE_AUTH_DIR="$BE_PROJECT_DIR/common/auth/keycloak"
BE_DOMAIN_AUTH_DIR="$BE_PROJECT_DIR/domain/auth"
BE_DATA_AUTH_DIR="$BE_PROJECT_DIR/data/auth"

CLUSTER_NAME="local-dev"
NAMESPACE="dev"

# ── 플래그 ────────────────────────────────────────────────────────────────────
LIGHT_MODE=false
MODE="all"

# ── 색상 ──────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${BLUE}══════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════════${NC}"; }

# ── 인자 파싱 ────────────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --light)     LIGHT_MODE=true; shift ;;
            --apps-only) MODE="apps-only"; shift ;;
            --infra-only) MODE="infra-only"; shift ;;
            --cleanup)   MODE="cleanup"; shift ;;
            --pause)     MODE="pause"; shift ;;
            --resume)    MODE="resume"; shift ;;
            --status)    MODE="status"; shift ;;
            --help|-h)   usage; exit 0 ;;
            *) log_error "알 수 없는 옵션: $1"; usage; exit 1 ;;
        esac
    done
}

usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  (없음)         전체 배포 (인프라 + 브로커 + 앱)"
    echo "  --light        경량 모드 (16GB RAM 이하 권장)"
    echo "  --apps-only    앱 서비스만 재배포"
    echo "  --infra-only   인프라만 배포"
    echo "  --cleanup      전체 리소스 정리"
    echo "  --pause        모든 배포 컨테이너 일시 중지 (replicas → 0)"
    echo "  --resume       일시 중지된 컨테이너 다시 시작 (replicas → 1)"
    echo "  --status       현재 배포 상태 확인"
    echo ""
    echo "조합 예시:"
    echo "  $0 --light              경량 전체 배포"
    echo "  $0 --light --apps-only  경량 모드로 앱만 재배포"
}

# ── 전제 조건 확인 ────────────────────────────────────────────────────────────
check_prerequisites() {
    log_step "전제 조건 확인"

    local missing=()

    command -v docker  >/dev/null 2>&1 || missing+=("docker")
    command -v kind    >/dev/null 2>&1 || missing+=("kind")
    command -v kubectl >/dev/null 2>&1 || missing+=("kubectl")
    command -v java    >/dev/null 2>&1 || missing+=("java (JDK 17)")

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "다음 도구가 설치되어 있지 않습니다: ${missing[*]}"
        echo "  brew install kind kubectl"
        echo "  Docker Desktop 설치 필요"
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker가 실행되고 있지 않습니다. Docker Desktop을 시작해주세요."
        exit 1
    fi

    if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log_error "Kind 클러스터 '${CLUSTER_NAME}'가 없습니다."
        echo "  먼저 Terraform으로 클러스터를 생성하세요:"
        echo "  cd $INFRA_LOCAL_DIR && terraform init && terraform apply"
        exit 1
    fi

    kind export kubeconfig --name "$CLUSTER_NAME" 2>/dev/null

    if [ ! -d "$BE_AUTH_DIR" ]; then
        log_error "BE 프로젝트를 찾을 수 없습니다: $BE_AUTH_DIR"
        exit 1
    fi

    if [ "$LIGHT_MODE" = true ]; then
        echo ""
        log_info "경량 모드 활성화"
        echo -e "  ${CYAN}브로커 인프라 스킵 (kafka-business, redis-business, postgres-booking)${NC}"
        echo ""
    fi

    log_info "전제 조건 확인 완료"
}

# ── Java 빌드 ──────────────────────────────────────────────────────────────────
build_java() {
    log_step "Java 프로젝트 빌드"

    cd "$BE_PROJECT_DIR"

    if [ ! -f "./gradlew" ]; then
        log_error "gradlew를 찾을 수 없습니다: $BE_PROJECT_DIR"
        exit 1
    fi

    chmod +x ./gradlew
    ./gradlew clean build -x test --no-daemon

    log_info "Java 빌드 완료"
}

# ── Docker 이미지 빌드 ────────────────────────────────────────────────────────
build_images() {
    log_step "Docker 이미지 빌드"

    cd "$BE_AUTH_DIR"

    # 1) 커스텀 Keycloak 이미지 (테마 + Realm 포함)
    log_info "Keycloak 커스텀 이미지 빌드 중..."
    local TEMP_DOCKERFILE
    TEMP_DOCKERFILE=$(mktemp)
    cat > "$TEMP_DOCKERFILE" <<'DOCKERFILE'
FROM quay.io/keycloak/keycloak:26.0
COPY theme/ /opt/keycloak/themes/
COPY docker/keycloak/realm-export.json /tmp/realm-export-template.json
COPY docker/keycloak/init-realm.sh /tmp/init-realm.sh
USER root
RUN chmod +x /tmp/init-realm.sh
USER keycloak
ENTRYPOINT ["/bin/bash", "/tmp/init-realm.sh"]
DOCKERFILE

    docker build -t keycloak-local:latest -f "$TEMP_DOCKERFILE" "$BE_AUTH_DIR"
    rm -f "$TEMP_DOCKERFILE"

    # 2) Gateway Service
    log_info "Gateway Service 이미지 빌드 중..."
    docker build -t gateway-service:local -f "$BE_DOMAIN_AUTH_DIR/gateway-service/Dockerfile" "$BE_PROJECT_DIR"

    # 3) User Command Service
    log_info "User Command Service 이미지 빌드 중..."
    docker build -t user-command-service:local -f "$BE_DOMAIN_AUTH_DIR/user-command-service/Dockerfile" "$BE_PROJECT_DIR"

    # 4) User Query Service
    log_info "User Query Service 이미지 빌드 중..."
    docker build -t user-query-service:local -f "$BE_DOMAIN_AUTH_DIR/user-query-service/Dockerfile" "$BE_PROJECT_DIR"

    # 5) Email Service
    log_info "Email Service 이미지 빌드 중..."
    docker build -t email-service:local -f "$BE_DOMAIN_AUTH_DIR/email-service/Dockerfile" "$BE_PROJECT_DIR"

    # 6) User Write Service (data layer)
    log_info "User Write Service 이미지 빌드 중..."
    docker build -t user-write-service:local -f "$BE_DATA_AUTH_DIR/user-write-service/Dockerfile" "$BE_PROJECT_DIR"

    # 7) User Read Service (data layer)
    log_info "User Read Service 이미지 빌드 중..."
    docker build -t user-read-service:local -f "$BE_DATA_AUTH_DIR/user-read-service/Dockerfile" "$BE_PROJECT_DIR"

    log_info "Docker 이미지 빌드 완료"
}

# ── Kind 클러스터에 이미지 로드 ───────────────────────────────────────────────
load_images() {
    log_step "Kind 클러스터에 이미지 로드"

    local images=("keycloak-local:latest" "gateway-service:local" "user-command-service:local" "user-query-service:local" "email-service:local" "user-write-service:local" "user-read-service:local")

    for img in "${images[@]}"; do
        log_info "로드 중: $img"
        kind load docker-image "$img" --name "$CLUSTER_NAME"
    done

    log_info "이미지 로드 완료"
}

# ── MinIO TLS 인증서 생성 & Secret ───────────────────────────────────────────
ensure_minio_tls() {
    local CERT_DIR="$INFRA_LOCAL_DIR/.certs/minio"

    # Secret이 이미 존재하면 스킵
    if kubectl -n "$NAMESPACE" get secret minio-tls >/dev/null 2>&1; then
        log_info "MinIO TLS Secret이 이미 존재합니다 (스킵)"
        return
    fi

    log_info "MinIO TLS 인증서 생성 중..."
    mkdir -p "$CERT_DIR"

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout "$CERT_DIR/private.key" \
        -out "$CERT_DIR/public.crt" \
        -subj "/CN=minio" \
        -addext "subjectAltName=DNS:minio,DNS:minio.dev.svc.cluster.local,DNS:localhost,IP:127.0.0.1" \
        2>/dev/null

    kubectl -n "$NAMESPACE" create secret generic minio-tls \
        --from-file=public.crt="$CERT_DIR/public.crt" \
        --from-file=private.key="$CERT_DIR/private.key"

    log_info "MinIO TLS Secret 생성 완료"

    # macOS 키체인 자동 등록
    if [[ "$(uname)" == "Darwin" ]]; then
        log_info "macOS 키체인에 MinIO 인증서 등록 중 (sudo 필요)..."
        sudo security add-trusted-cert -d -r trustRoot \
            -k /Library/Keychains/System.keychain \
            "$CERT_DIR/public.crt" 2>/dev/null \
            && log_info "키체인 등록 완료 (이후 재배포 시 자동 스킵)" \
            || log_warn "키체인 등록 실패 — 수동으로 등록하세요: sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CERT_DIR/public.crt"
    fi
}

# ── 인프라 배포 ──────────────────────────────────────────────────────────────
deploy_infra() {
    log_step "인프라 서비스 배포"

    kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

    # ConfigMap & Secret
    log_info "ConfigMap & Secret 적용..."
    kubectl apply -f "$MANIFESTS_DIR/configmap.yaml"
    kubectl apply -f "$MANIFESTS_DIR/secret.yaml"

    # Auth 인프라
    log_info "Auth 인프라 배포 (PostgreSQL, Kafka, Redis)..."
    kubectl apply -f "$MANIFESTS_DIR/postgres-keycloak.yaml"
    kubectl apply -f "$MANIFESTS_DIR/postgres-user.yaml"
    kubectl apply -f "$MANIFESTS_DIR/kafka.yaml"
    kubectl apply -f "$MANIFESTS_DIR/redis.yaml"

    # MinIO (S3-compatible object storage)
    log_info "MinIO (Object Storage) 배포..."
    ensure_minio_tls
    kubectl apply -f "$MANIFESTS_DIR/minio.yaml"

    # Broker 인프라 (경량 모드 시 스킵)
    if [ "$LIGHT_MODE" = false ]; then
        log_info "Broker 인프라 배포 (Kafka-Business, Redis-Business, PostgreSQL-Booking)..."
        kubectl apply -f "$MANIFESTS_DIR/kafka-business.yaml"
        kubectl apply -f "$MANIFESTS_DIR/redis-business.yaml"
        kubectl apply -f "$MANIFESTS_DIR/postgres-booking.yaml"
    else
        log_warn "경량 모드: Broker 인프라 스킵"
    fi

    # 인프라 Ready 대기
    log_info "인프라 서비스 Ready 대기 중..."
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=postgres-keycloak --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=user-postgres --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=kafka --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=redis --timeout=60s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=minio --timeout=60s 2>/dev/null || true

    # Keycloak 배포
    log_info "Keycloak 배포..."
    kubectl apply -f "$MANIFESTS_DIR/keycloak.yaml"

    log_info "Keycloak Ready 대기 중 (최대 3분)..."
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=keycloak --timeout=180s 2>/dev/null \
        || log_warn "Keycloak이 아직 준비되지 않았을 수 있습니다. kubectl -n dev get pods 로 확인하세요."

    log_info "인프라 배포 완료"
}

# ── 앱 서비스 배포 ────────────────────────────────────────────────────────────
deploy_apps() {
    log_step "앱 서비스 배포"

    # Data 서비스 먼저 배포 (domain 서비스가 의존)
    kubectl apply -f "$MANIFESTS_DIR/user-write-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/user-read-service.yaml"

    kubectl apply -f "$MANIFESTS_DIR/gateway-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/user-command-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/user-query-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/email-service.yaml"

    # 이미지 태그가 동일(:local)하므로 rollout restart로 새 이미지 반영
    log_info "앱 서비스 롤링 재시작..."
    kubectl -n "$NAMESPACE" rollout restart deployment/user-write-service
    kubectl -n "$NAMESPACE" rollout restart deployment/user-read-service
    kubectl -n "$NAMESPACE" rollout restart deployment/gateway-service
    kubectl -n "$NAMESPACE" rollout restart deployment/user-command-service
    kubectl -n "$NAMESPACE" rollout restart deployment/user-query-service
    kubectl -n "$NAMESPACE" rollout restart deployment/email-service

    log_info "앱 서비스 Ready 대기 중..."
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=user-write-service --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=user-read-service --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=gateway-service --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=user-command-service --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=user-query-service --timeout=120s 2>/dev/null || true
    kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=email-service --timeout=120s 2>/dev/null || true

    log_info "앱 서비스 배포 완료"
}


# ── 일시 중지 (replicas → 0) ──────────────────────────────────────────────────
pause_deployments() {
    log_step "배포 컨테이너 일시 중지"

    local deployments
    deployments=$(kubectl -n "$NAMESPACE" get deployments -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

    if [ -z "$deployments" ]; then
        log_warn "${NAMESPACE} 네임스페이스에 Deployment가 없습니다."
        return
    fi

    for dep in $deployments; do
        log_info "일시 중지: $dep (replicas → 0)"
        kubectl -n "$NAMESPACE" scale deployment/"$dep" --replicas=0
    done

    echo ""
    log_info "모든 Deployment가 일시 중지되었습니다."
    echo -e "  ${CYAN}다시 시작하려면: $0 --resume${NC}"
    echo ""
}

# ── 다시 시작 (replicas → 1) ─────────────────────────────────────────────────
resume_deployments() {
    log_step "배포 컨테이너 다시 시작"

    local deployments
    deployments=$(kubectl -n "$NAMESPACE" get deployments -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

    if [ -z "$deployments" ]; then
        log_warn "${NAMESPACE} 네임스페이스에 Deployment가 없습니다."
        return
    fi

    for dep in $deployments; do
        local current_replicas
        current_replicas=$(kubectl -n "$NAMESPACE" get deployment/"$dep" -o jsonpath='{.spec.replicas}' 2>/dev/null)
        if [ "$current_replicas" = "0" ]; then
            log_info "다시 시작: $dep (replicas → 1)"
            kubectl -n "$NAMESPACE" scale deployment/"$dep" --replicas=1
        else
            log_info "이미 실행 중: $dep (replicas: $current_replicas)"
        fi
    done

    log_info "Deployment Ready 대기 중..."
    kubectl -n "$NAMESPACE" wait --for=condition=available deployment --all --timeout=180s 2>/dev/null \
        || log_warn "일부 Deployment가 아직 준비되지 않았을 수 있습니다. --status 로 확인하세요."

    echo ""
    log_info "모든 Deployment가 다시 시작되었습니다."
    echo ""
}

# ── 전체 정리 ────────────────────────────────────────────────────────────────
cleanup() {
    log_step "로컬 배포 리소스 정리"

    log_info "dev 네임스페이스의 모든 리소스 삭제 중..."
    kubectl delete -f "$MANIFESTS_DIR/" --ignore-not-found=true 2>/dev/null || true

    log_info "PVC 정리 중..."
    kubectl -n "$NAMESPACE" delete pvc --all --ignore-not-found=true 2>/dev/null || true

    log_info "정리 완료"
}

# ── 상태 출력 ────────────────────────────────────────────────────────────────
print_status() {
    log_step "배포 상태"

    echo ""
    kubectl -n "$NAMESPACE" get pods -o wide
    echo ""
    kubectl -n "$NAMESPACE" get svc
    echo ""
    kubectl -n "$NAMESPACE" get ingress 2>/dev/null || true
    echo ""

    log_step "메모리 요약 (매니페스트 기준)"
    echo ""
    echo -e "  ${CYAN}서비스                    requests   limits${NC}"
    echo "  ────────────────────────────────────────────"
    echo "  PostgreSQL (keycloak) :   48Mi     128Mi"
    echo "  PostgreSQL (user)     :   48Mi     128Mi"
    echo "  Kafka                 :  256Mi     512Mi"
    echo "  Redis                 :   32Mi      64Mi"
    echo "  Keycloak              :  256Mi     512Mi"
    echo "  Gateway Service       :  128Mi     384Mi"
    echo "  User Command Service  :  128Mi     320Mi"
    echo "  User Query Service    :  128Mi     320Mi"
    echo "  User Write Service    :  128Mi     320Mi"
    echo "  User Read Service     :  128Mi     320Mi"
    echo "  Email Service         :  128Mi     384Mi"
    echo "  MinIO                 :  128Mi     256Mi"
    echo "  ────────────────────────────────────────────"
    echo -e "  ${GREEN}합계                    : 1.5GB     3.7GB${NC}"
    echo -e "  ${YELLOW}+ Kind 노드 + Docker ≈ 총 5~6GB 사용${NC}"
    echo ""

    log_step "접속 정보"
    echo ""
    echo "  NodePort로 직접 접근 (port-forward 불필요):"
    echo ""
    echo "  Gateway API:   http://localhost:8443   (NodePort 30080)"
    echo "  Keycloak:      http://localhost:9090   (NodePort 30090)"
    echo "    Admin:       admin / admin"
    echo "  MinIO API:     https://localhost:9000   (NodePort 30100 → host 9000, TLS)"
    echo "  MinIO Console: https://localhost:9001   (NodePort 30101 → host 9001, TLS)"
    echo "    Login:       minioadmin / minioadmin1234"
    echo ""
    echo "  로그 확인:"
    echo "    kubectl -n dev logs -f deploy/gateway-service"
    echo "    kubectl -n dev logs -f deploy/keycloak"
    echo ""

    echo -e "  ${YELLOW}[TIP] Docker Desktop → Settings → Resources → Memory: 8GB 권장${NC}"
    echo ""
}

# ── 메인 ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    case "$MODE" in
        cleanup)
            check_prerequisites
            cleanup
            ;;
        pause)
            kind export kubeconfig --name "$CLUSTER_NAME" 2>/dev/null
            pause_deployments
            ;;
        resume)
            kind export kubeconfig --name "$CLUSTER_NAME" 2>/dev/null
            resume_deployments
            ;;
        status)
            kind export kubeconfig --name "$CLUSTER_NAME" 2>/dev/null
            print_status
            ;;
        infra-only)
            check_prerequisites
            deploy_infra
            print_status
            ;;
        apps-only)
            check_prerequisites
            build_java
            build_images
            load_images
            deploy_apps
            print_status
            ;;
        all)
            check_prerequisites
            build_java
            build_images
            load_images
            deploy_infra
            deploy_apps
            print_status
            ;;
    esac
}

main "$@"
