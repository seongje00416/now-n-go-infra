output "task_execution_role_arn" {
  description = "ECS 태스크 실행 역할 ARN (모든 서비스 공유)"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arns" {
  description = "도메인별 ECS 태스크 역할 ARN 맵"
  value = {
    default    = aws_iam_role.default_task.arn
    auth       = aws_iam_role.auth_task.arn
    booking    = aws_iam_role.booking_task.arn
    travel-ai  = aws_iam_role.travel_ai_task.arn
  }
}
