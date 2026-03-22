# ============================================================
# EKS 클러스터 보안 그룹 — 외부 접근 규칙
#  EKS 관리형 노드 그룹은 클러스터 보안 그룹을 워커 노드에 공유
#  CLB/NLB → 노드 NodePort 트래픽을 허용하기 위해 인바운드 규칙 추가
# ============================================================

# ── NodePort 범위 허용 ────────────────────────────────────────
#  LoadBalancer 타입 서비스 생성 시 AWS CCM이 자동으로 CLB를 만들고
#  NodePort(30000-32767)로 트래픽을 포워딩함
#  해당 포트 범위를 외부(0.0.0.0/0)에서 허용
resource "aws_security_group_rule" "eks_nodeport_inbound" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Allow external traffic to NodePort range (CLB/NLB)"
}

# ── HTTP/HTTPS 허용 ───────────────────────────────────────────
#  NLB 어노테이션 사용 시 NLB가 80/443 포트로 직접 노드에 접근
resource "aws_security_group_rule" "eks_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Allow inbound HTTP from internet"
}

resource "aws_security_group_rule" "eks_https_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Allow inbound HTTPS from internet"
}

# ── gateway-service 직접 포트 허용 ───────────────────────────
#  gateway-service가 8080 포트를 사용하므로 CLB 리스너 포트도 허용
resource "aws_security_group_rule" "eks_gateway_inbound" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Allow inbound 8080 for gateway-service"
}

# ============================================================
# gateway-service — NLB 어노테이션 패치
#  기본 CLB 대신 NLB(Network Load Balancer) 사용
#  NLB는 CLB보다 지연 시간이 낮고 EKS에 최적화됨
#  preserve_client_ip: 실제 클라이언트 IP를 파드까지 전달
# ============================================================
resource "kubernetes_annotations" "gateway_service_nlb" {
  api_version = "v1"
  kind        = "Service"

  metadata {
    name      = "gateway-service"
    namespace = "prod"
  }

  annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
  }

  # 기존 어노테이션 덮어쓰기 허용
  force = true
}
