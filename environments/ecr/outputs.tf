# ============================================================
# Outputs - CI/CD 파이프라인에서 참조할 레지스트리 URL
# ============================================================

output "ecr_registry" {
  description = "ECR 레지스트리 베이스 URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repository_urls" {
  description = "각 서비스의 ECR 레포지토리 전체 URL"
  value       = { for k in var.ecr_repositories : k => "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.cluster_name}/${k}" }
  depends_on  = [null_resource.ecr_repos]
}
