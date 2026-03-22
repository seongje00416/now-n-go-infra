# ============================================================
# ECR (Elastic Container Registry) - 서비스별 이미지 저장소
#  각 마이크로서비스의 Docker 이미지를 저장하는 프라이빗 레지스트리
# ============================================================

locals {
  ecr_services = [
    // infra service
    "elasticsearch",

    // data service
    "gateway-service",
    "user-write-service",
    "user-read-service",
    "products-write-service",
    "products-read-service",
    "skus-write-service",
    "skus-read-service",
    "sku-flights-write-service",
    "sku-flights-read-service",
    "sku-leisure-write-service",
    "sku-leisure-read-service",
    "sku-landmark-write-service",
    "sku-landmark-read-service",
    "sku-stay-write-service",
    "sku-stay-read-service",
    "sku-show-write-service",
    "sku-show-read-service",
    "sku-transport-write-service",
    "sku-transport-read-service",
    "orders-write-service",
    "orders-read-service",
    "order-items-write-service",
    "order-items-read-service",
    "payments-write-service",
    "payments-read-service",
    "location-write-service",
    "location-read-service",
    "review-write-service",
    "review-read-service",
    "seat-write-service",
    "seat-read-service",
    "media-data",
    "wishlist-data",
    "cancellation-policy-data",

    // domain service
    "user-service",
    "email-service",
    "products-create-service",
    "products-list-service",
    "create-stay-product-service",
    "create-transport-product-service",
    "create-flight-product-service",
    "reviews-create-service",
    "reviews-list-service",
    "wishlist-service",
    "reservation-travel-service",
    "publish-order-service",
    "save-payments-service",
    "toss-payments-service",
    "data-bastion-service",
    "travel-ai",
  ]
}

data "aws_caller_identity" "current" {}

# ============================================================
# ECR 레포지토리 생성 (이미 존재하는 경우 건너뜀)
#  AWS CLI 기반 idempotent 생성 — RepositoryAlreadyExistsException 무시
# ============================================================
resource "null_resource" "ecr_repos" {
  for_each = toset(local.ecr_services)

  triggers = {
    repo_name = "${var.cluster_name}/${each.key}"
  }

  provisioner "local-exec" {
    command = "aws ecr describe-repositories --repository-names ${var.cluster_name}/${each.key} --region ${var.aws_region} 2>nul || aws ecr create-repository --repository-name ${var.cluster_name}/${each.key} --region ${var.aws_region} --image-tag-mutability MUTABLE --image-scanning-configuration scanOnPush=true"
  }
}

# ============================================================
# Outputs - CI/CD 파이프라인에서 참조할 레지스트리 URL
# ============================================================
output "ecr_registry" {
  description = "ECR 레지스트리 베이스 URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repository_urls" {
  description = "각 서비스의 ECR 레포지토리 URL"
  value       = { for k in local.ecr_services : k => "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.cluster_name}/${k}" }
  depends_on  = [null_resource.ecr_repos]
}
