# ============================================================
# AWS Load Balancer Controller (LBC) — Helm 설치
#  Ingress 리소스를 감지해 ALB를 자동 프로비저닝
# ============================================================
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.3"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lbc.arn
  }
  set {
    name  = "region"
    value = var.aws_region
  }
  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.lbc,
    aws_eks_addon.vpc_cni,
  ]
}

# ============================================================
# gateway-service Ingress → ALB 프로비저닝 트리거
#  internet-facing ALB, instance mode, HTTP 80
# ============================================================
resource "kubernetes_ingress_v1" "gateway" {
  metadata {
    name      = "gateway-ingress"
    namespace = kubernetes_namespace.prod.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                             = "alb"
      "alb.ingress.kubernetes.io/scheme"                       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"                  = "instance"
      "alb.ingress.kubernetes.io/listen-ports"                 = jsonencode([{ HTTP = 80 }])
      "alb.ingress.kubernetes.io/healthcheck-path"             = "/actuator/health"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "gateway-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.aws_lbc]
}

output "alb_dns" {
  description = "ALB DNS 주소 (배포 후 수 분 소요)"
  value       = try(kubernetes_ingress_v1.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
}
