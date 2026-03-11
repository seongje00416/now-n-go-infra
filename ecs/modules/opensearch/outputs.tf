# ============================================================
# OpenSearch 모듈 출력값
# ============================================================

output "endpoint" {
  description = "OpenSearch 도메인 엔드포인트 URL"
  value       = aws_opensearch_domain.this.endpoint
}

output "domain_arn" {
  description = "OpenSearch 도메인 ARN"
  value       = aws_opensearch_domain.this.arn
}

output "domain_id" {
  description = "OpenSearch 도메인 ID"
  value       = aws_opensearch_domain.this.domain_id
}
