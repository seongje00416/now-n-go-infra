# =============================================================================
# 모니터링 모듈 — 출력값
# =============================================================================

output "log_group_names" {
  description = "서비스 이름 → CloudWatch 로그 그룹 이름 매핑"
  value       = { for k, v in aws_cloudwatch_log_group.services : k => v.name }
}

output "log_group_arns" {
  description = "서비스 이름 → CloudWatch 로그 그룹 ARN 매핑"
  value       = { for k, v in aws_cloudwatch_log_group.services : k => v.arn }
}

output "sns_topic_arn" {
  description = "ECS 알람 SNS 토픽 ARN"
  value       = aws_sns_topic.alerts.arn
}
