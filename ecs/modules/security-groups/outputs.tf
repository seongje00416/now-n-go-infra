output "alb_sg_id" {
  description = "ALB 보안 그룹 ID"
  value       = aws_security_group.alb.id
}

output "ecs_service_sg_id" {
  description = "ECS 서비스 보안 그룹 ID"
  value       = aws_security_group.ecs_service.id
}

output "rds_sg_id" {
  description = "RDS PostgreSQL 보안 그룹 ID"
  value       = aws_security_group.rds.id
}

output "redis_sg_id" {
  description = "ElastiCache Redis 보안 그룹 ID"
  value       = aws_security_group.redis.id
}

output "msk_sg_id" {
  description = "MSK Kafka 보안 그룹 ID"
  value       = aws_security_group.msk.id
}

output "opensearch_sg_id" {
  description = "OpenSearch 보안 그룹 ID"
  value       = aws_security_group.opensearch.id
}

output "keycloak_sg_id" {
  description = "Keycloak 보안 그룹 ID"
  value       = aws_security_group.keycloak.id
}
