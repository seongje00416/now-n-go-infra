# ============================================================
# Secrets 모듈 변수 정의
# ============================================================

variable "project_name" {
  description = "프로젝트 이름 (태그 및 설명에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
}

variable "db_credentials" {
  description = "RDS 마스터 자격증명 (username, password)"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "redis_auth_password" {
  description = "auth Redis auth 토큰"
  type        = string
  sensitive   = true
}

variable "redis_business_password" {
  description = "business Redis auth 토큰"
  type        = string
  sensitive   = true
}

variable "encryption_aes_key" {
  description = "AES-256-GCM 암호화 키 (common-crypto 모듈용)"
  type        = string
  sensitive   = true
}

variable "encryption_hmac_key" {
  description = "HMAC-SHA256 서명 키 (common-crypto 모듈용)"
  type        = string
  sensitive   = true
}

variable "internal_api_key" {
  description = "내부 서비스 간 통신 API Key (X-Internal-Api-Key 헤더)"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Keycloak 어드민 계정 비밀번호"
  type        = string
  sensitive   = true
}

variable "rds_primary_endpoint" {
  description = "RDS Primary 엔드포인트 (SSM에 저장할 비민감 설정값)"
  type        = string
}

variable "rds_replica_endpoint" {
  description = "RDS Read Replica 엔드포인트 (SSM에 저장할 비민감 설정값)"
  type        = string
}

variable "db_name" {
  description = "데이터베이스 이름 (SSM에 저장할 비민감 설정값)"
  type        = string
}
