#!/bin/bash
set -euo pipefail

# =============================================================================
# Kafka 빌드 & 로컬 클러스터 배포 스크립트
# 사전 조건: Docker, Kind, Helm, kubectl 설치 필요
# =============================================================================

# ── 설정 변수 ──────────────────────────────────────────────────────────────────
IMAGE_NAME="kafka-business"
KIND_CLUSTER_NAME="local-dev"
IMAGE_TAG="3.9.1"
HELM_RELEASE="kafka"
HELM_CHART_DIR="./menifest"
NAMESPACE="kafka"
SECRET_NAME="kafka-cluster-id"

# ── 색상 출력 헬퍼 ─────────────────────────────────────────────────────────────
info()    { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[OK]\033[0m $*"; }
error()   { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; exit 1; }

# ── 사전 조건 체크 ─────────────────────────────────────────────────────────────
info "사전 조건 확인 중..."
for cmd in docker kind helm kubectl; do
  command -v "$cmd" &>/dev/null || error "'$cmd' 가 설치되어 있지 않습니다."
done

kind get clusters | grep -q . || error "실행 중인 Kind 클러스터가 없습니다. 'kind create cluster' 를 먼저 실행하세요."
success "사전 조건 확인 완료"

# ── 1. Docker 이미지 빌드 ──────────────────────────────────────────────────────
info "Docker 이미지 빌드 중... (${IMAGE_NAME}:${IMAGE_TAG})"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
success "이미지 빌드 완료"

# ── 2. Kind 클러스터에 이미지 로드 ────────────────────────────────────────────
info "Kind 클러스터에 이미지 로드 중..."
kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${KIND_CLUSTER_NAME}"
success "이미지 로드 완료"

# ── 3. 네임스페이스 생성 ───────────────────────────────────────────────────────
if ! kubectl get namespace "${NAMESPACE}" &>/dev/null; then
  info "네임스페이스 생성 중... (${NAMESPACE})"
  kubectl create namespace "${NAMESPACE}"
fi
success "네임스페이스 준비 완료"

# ── 4. Cluster ID Secret 생성 (없을 때만) ─────────────────────────────────────
if ! kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" &>/dev/null; then
  info "Kafka Cluster ID 생성 중..."
  CLUSTER_ID=$(docker run --rm --entrypoint kafka-storage.sh "${IMAGE_NAME}:${IMAGE_TAG}" random-uuid)
  kubectl create secret generic "${SECRET_NAME}" \
    --from-literal=KAFKA_CLUSTER_ID="${CLUSTER_ID}" \
    -n "${NAMESPACE}"
  success "Secret 생성 완료 (KAFKA_CLUSTER_ID=${CLUSTER_ID})"
else
  info "기존 Secret '${SECRET_NAME}' 을 재사용합니다."
fi

# ── 5. Helm 배포 ───────────────────────────────────────────────────────────────
info "Helm Chart 배포 중..."
helm upgrade --install "${HELM_RELEASE}" "${HELM_CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --wait \
  --timeout 3m

success "Helm 배포 완료"

# ── 6. 배포 상태 확인 ──────────────────────────────────────────────────────────
echo ""
info "배포 상태:"
kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}"
echo ""
info "접속 주소 (클러스터 내부): ${HELM_RELEASE}.${NAMESPACE}.svc.cluster.local:9092"
success "완료!"