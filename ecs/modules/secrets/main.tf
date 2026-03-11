# ============================================================
# Secrets Manager & SSM Parameter Store 모듈
# - 민감 정보: Secrets Manager (암호화 저장)
# - 비민감 설정값: SSM Parameter Store (String 타입)
# - 시크릿 값은 tfvars 또는 별도 파이프라인으로 주입
# ============================================================

# ------------------------------
# Secrets Manager — RDS 자격증명
# - JSON 형식: { username, password }
# ------------------------------
resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "nowandgo/rds/credentials"
  description = "${var.project_name} RDS 마스터 사용자 자격증명 (username/password)"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_credentials.username
    password = var.db_credentials.password
  })
}

# ------------------------------
# Secrets Manager — auth Redis 비밀번호
# ------------------------------
resource "aws_secretsmanager_secret" "redis_auth_password" {
  name        = "nowandgo/redis/auth-password"
  description = "${var.project_name} auth Redis auth 토큰"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth_password" {
  secret_id     = aws_secretsmanager_secret.redis_auth_password.id
  secret_string = var.redis_auth_password
}

# ------------------------------
# Secrets Manager — business Redis 비밀번호
# ------------------------------
resource "aws_secretsmanager_secret" "redis_business_password" {
  name        = "nowandgo/redis/business-password"
  description = "${var.project_name} business Redis auth 토큰"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "redis_business_password" {
  secret_id     = aws_secretsmanager_secret.redis_business_password.id
  secret_string = var.redis_business_password
}

# ------------------------------
# Secrets Manager — 암호화 키
# - JSON 형식: { aes_key, hmac_key }
# - common-crypto 모듈 (AES-256-GCM, HMAC-SHA256) 에서 사용
# ------------------------------
resource "aws_secretsmanager_secret" "encryption_keys" {
  name        = "nowandgo/encryption/keys"
  description = "${var.project_name} AES-256-GCM 암호화 키 및 HMAC-SHA256 서명 키"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "encryption_keys" {
  secret_id = aws_secretsmanager_secret.encryption_keys.id
  secret_string = jsonencode({
    aes_key  = var.encryption_aes_key
    hmac_key = var.encryption_hmac_key
  })
}

# ------------------------------
# Secrets Manager — Internal API Key
# - 게이트웨이 → 도메인 서비스 내부 통신 인증 (X-Internal-Api-Key 헤더)
# ------------------------------
resource "aws_secretsmanager_secret" "internal_api_key" {
  name        = "nowandgo/internal-api-key"
  description = "${var.project_name} 내부 서비스 간 통신 API Key (X-Internal-Api-Key)"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "internal_api_key" {
  secret_id     = aws_secretsmanager_secret.internal_api_key.id
  secret_string = var.internal_api_key
}

# ------------------------------
# Secrets Manager — Keycloak Admin 비밀번호
# ------------------------------
resource "aws_secretsmanager_secret" "keycloak_admin_password" {
  name        = "nowandgo/keycloak/admin-password"
  description = "${var.project_name} Keycloak 어드민 계정 비밀번호"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "keycloak_admin_password" {
  secret_id     = aws_secretsmanager_secret.keycloak_admin_password.id
  secret_string = var.keycloak_admin_password
}

# ------------------------------
# SSM Parameter Store — RDS Primary 엔드포인트
# - 비민감 설정값, 애플리케이션 시작 시 참조
# ------------------------------
resource "aws_ssm_parameter" "rds_primary_endpoint" {
  name        = "/nowandgo/rds/primary-endpoint"
  type        = "String"
  value       = var.rds_primary_endpoint
  description = "${var.project_name} RDS Primary 인스턴스 엔드포인트"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ------------------------------
# SSM Parameter Store — RDS Replica 엔드포인트
# ------------------------------
resource "aws_ssm_parameter" "rds_replica_endpoint" {
  name        = "/nowandgo/rds/replica-endpoint"
  type        = "String"
  value       = var.rds_replica_endpoint
  description = "${var.project_name} RDS Read Replica 엔드포인트"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ------------------------------
# SSM Parameter Store — DB 이름
# ------------------------------
resource "aws_ssm_parameter" "db_name" {
  name        = "/nowandgo/rds/db-name"
  type        = "String"
  value       = var.db_name
  description = "${var.project_name} 데이터베이스 이름"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
