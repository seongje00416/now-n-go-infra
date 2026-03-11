# =============================================================================
# ECR 모듈 — 출력값
# =============================================================================

output "repository_urls" {
  description = "서비스 이름 → ECR 저장소 URL 매핑"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}
