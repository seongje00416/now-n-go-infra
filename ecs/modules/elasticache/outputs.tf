# ============================================================
# ElastiCache 모듈 출력값
# ============================================================

output "auth_endpoint" {
  description = "auth Redis Primary 엔드포인트 호스트"
  value       = aws_elasticache_replication_group.auth.primary_endpoint_address
}

output "auth_port" {
  description = "auth Redis 포트"
  value       = aws_elasticache_replication_group.auth.port
}

output "business_endpoint" {
  description = "business Redis Primary 엔드포인트 호스트"
  value       = aws_elasticache_replication_group.business.primary_endpoint_address
}

output "business_port" {
  description = "business Redis 포트"
  value       = aws_elasticache_replication_group.business.port
}
