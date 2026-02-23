resource "helm_release" "kafka" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  namespace  = "kafka"
  version    = "26.8.5"

  create_namespace = true

  set {
    name  = "kraft.enabled"
    value = "true"
  }

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  # Kind의 local-storage 대신 EBS StorageClass 사용
  set {
    name  = "controller.persistence.storageClass"
    value = "ebs-storage"
  }

  set {
    name  = "controller.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "listeners.client.protocol"
    value = "PLAINTEXT"
  }

  set {
    name  = "listeners.controller.protocol"
    value = "PLAINTEXT"
  }

  depends_on = [
    aws_eks_node_group.main,
    kubernetes_storage_class.ebs_storage,
    aws_eks_addon.ebs_csi_driver
  ]
}