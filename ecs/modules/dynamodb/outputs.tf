# ============================================================
# DynamoDB 모듈 출력값
# ============================================================

output "table_name" {
  description = "DynamoDB orders 테이블 이름"
  value       = aws_dynamodb_table.orders.name
}

output "table_arn" {
  description = "DynamoDB orders 테이블 ARN"
  value       = aws_dynamodb_table.orders.arn
}
