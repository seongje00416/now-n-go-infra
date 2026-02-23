#!/bin/bash
set -euo pipefail

KAFKA_CONFIG="${KAFKA_HOME}/config/kraft/server.properties"
KAFKA_CONFIG_RESOLVED="/tmp/server.properties"

# ── ConfigMap의 server.properties에서 변수 치환 ────────────────────────────────
# Kafka는 shell 변수 치환을 하지 않으므로, 직접 치환한 뒤 임시 파일로 사용
echo "[entrypoint] server.properties 변수 치환 중..."
echo "[entrypoint]   KAFKA_NODE_ID=${KAFKA_NODE_ID}"
echo "[entrypoint]   KAFKA_POD_FQDN=${KAFKA_POD_FQDN}"

sed \
  -e "s|\${KAFKA_NODE_ID}|${KAFKA_NODE_ID}|g" \
  -e "s|\${KAFKA_POD_FQDN}|${KAFKA_POD_FQDN}|g" \
  "${KAFKA_CONFIG}" > "${KAFKA_CONFIG_RESOLVED}"

# ── KRaft 스토리지 초기화 (최초 1회만) ──────────────────────────────────────────
if [ ! -f "/var/kafka/logs/meta.properties" ]; then
    echo "[entrypoint] KRaft 스토리지 포맷 중... (cluster-id: ${KAFKA_CLUSTER_ID:?KAFKA_CLUSTER_ID is required})"
    kafka-storage.sh format \
        --config "${KAFKA_CONFIG_RESOLVED}" \
        --cluster-id "${KAFKA_CLUSTER_ID}" \
        --ignore-formatted
fi

# ── Kafka 시작 ───────────────────────────────────────────────────────────────
echo "[entrypoint] Kafka 브로커 시작..."
exec kafka-server-start.sh "${KAFKA_CONFIG_RESOLVED}"