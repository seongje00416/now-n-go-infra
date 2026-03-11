# =============================================================================
# ECS 클러스터 모듈 — 출력값
# =============================================================================

output "cluster_id" {
  description = "ECS 클러스터 ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS 클러스터 ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS 클러스터 이름"
  value       = aws_ecs_cluster.this.name
}
