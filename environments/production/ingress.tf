# ============================================================
# NGINX Ingress Controller
#  외부 인터넷 → NLB → nginx-ingress controller → 클러스터 내부 서비스
#  gateway-service를 포함한 모든 서비스의 외부 진입점 역할
# ============================================================
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  version          = "4.9.1"
  create_namespace = true

  # AWS NLB 사용 (CLB보다 성능 좋고 비용 효율적)
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  # 실제 클라이언트 IP를 서비스까지 전달
  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
  }

  depends_on = [aws_eks_node_group.main]
}

# ============================================================
# gateway-service 외부 접속 URL
#  NLB 호스트명을 output으로 노출
#  ※ NLB 프로비저닝에 수분이 걸릴 수 있음
#    호스트명이 비어있으면 잠시 후 terraform output 으로 재확인
# ============================================================
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress]
}

output "gateway_service_url" {
  description = "gateway-service 외부 접속 URL (NLB 호스트명)"
  value = try(
    "http://${data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname}",
    "NLB 프로비저닝 중 - 잠시 후 'terraform output gateway_service_url' 로 재확인하세요"
  )
}
