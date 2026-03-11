# ============================================================
# MSK 모듈 출력값
# ============================================================

output "auth_bootstrap_servers" {
  description = "auth MSK Serverless 클러스터 부트스트랩 서버 엔드포인트"
  value       = aws_msk_serverless_cluster.auth.bootstrap_brokers_sasl_iam
}

output "business_bootstrap_servers" {
  description = "business MSK Serverless 클러스터 부트스트랩 서버 엔드포인트"
  value       = aws_msk_serverless_cluster.business.bootstrap_brokers_sasl_iam
}

output "auth_cluster_arn" {
  description = "auth MSK Serverless 클러스터 ARN"
  value       = aws_msk_serverless_cluster.auth.arn
}

output "business_cluster_arn" {
  description = "business MSK Serverless 클러스터 ARN"
  value       = aws_msk_serverless_cluster.business.arn
}
