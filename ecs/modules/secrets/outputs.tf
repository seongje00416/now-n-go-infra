# ============================================================
# Secrets 모듈 출력값
# ============================================================

output "secret_arns" {
  description = "Secrets Manager 시크릿 ARN 맵"
  value = {
    rds_credentials         = aws_secretsmanager_secret.rds_credentials.arn
    redis_auth_password     = aws_secretsmanager_secret.redis_auth_password.arn
    redis_business_password = aws_secretsmanager_secret.redis_business_password.arn
    encryption_keys         = aws_secretsmanager_secret.encryption_keys.arn
    internal_api_key        = aws_secretsmanager_secret.internal_api_key.arn
    keycloak_admin_password = aws_secretsmanager_secret.keycloak_admin_password.arn
  }
}

output "ssm_parameter_arns" {
  description = "SSM Parameter Store 파라미터 ARN 맵"
  value = {
    rds_primary_endpoint = aws_ssm_parameter.rds_primary_endpoint.arn
    rds_replica_endpoint = aws_ssm_parameter.rds_replica_endpoint.arn
    db_name              = aws_ssm_parameter.db_name.arn
  }
}
