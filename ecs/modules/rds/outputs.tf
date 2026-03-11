# ============================================================
# RDS 모듈 출력값
# ============================================================

output "primary_endpoint" {
  description = "RDS Primary 인스턴스 엔드포인트 (호스트:포트)"
  value       = aws_db_instance.primary.endpoint
}

output "replica_endpoint" {
  description = "RDS Read Replica 엔드포인트 (호스트:포트)"
  value       = aws_db_instance.replica.endpoint
}

output "db_name" {
  description = "생성된 데이터베이스 이름"
  value       = aws_db_instance.primary.db_name
}

output "port" {
  description = "RDS 접속 포트"
  value       = aws_db_instance.primary.port
}
