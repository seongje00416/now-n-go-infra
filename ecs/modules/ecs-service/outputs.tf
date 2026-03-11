# =============================================================================
# ECS 서비스 모듈 — 출력값
# =============================================================================

output "service_id" {
  description = "ECS 서비스 ID"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "ECS 서비스 이름"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ECS 태스크 정의 ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "discovery_service_arn" {
  description = "Cloud Map 서비스 검색 ARN"
  value       = aws_service_discovery_service.this.arn
}
