resource "helm_release" "redis" {
  name      = "redis"
  chart     = "oci://registry-1.docker.io/bitnamicharts/redis"
  namespace = "redis"
  version   = "25.3.0"

  create_namespace = true
  timeout          = 180
  wait             = false
  atomic           = false

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.password"
    value = var.redis_password
  }

  set {
    name  = "master.persistence.storageClass"
    value = "local-storage"
  }

  set {
    name  = "master.persistence.size"
    value = "1Gi"
  }

  depends_on = [
    kind_cluster.default,
    kubernetes_storage_class.local_storage,
    helm_release.local_path_provisioner
  ]
}