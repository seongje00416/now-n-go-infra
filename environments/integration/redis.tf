resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = "redis"
  version    = "18.6.1"

  create_namespace = true

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.password"
    value = var.redis_password
  }

  # Kind의 local-storage 대신 EBS StorageClass 사용
  set {
    name  = "master.persistence.storageClass"
    value = "ebs-storage"
  }

  set {
    name  = "master.persistence.size"
    value = "5Gi"    # EKS는 EBS 최소 권장 크기 적용
  }

  depends_on = [
    aws_eks_node_group.main,
    kubernetes_storage_class.ebs_storage,
    aws_eks_addon.ebs_csi_driver
  ]
}