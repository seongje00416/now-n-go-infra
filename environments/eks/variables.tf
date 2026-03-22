variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "now-n-go-cluster"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "node_instance_type" {
  description = "노드 그룹 EC2 인스턴스 타입"
  type        = string
  default     = "t3.xlarge"
}

variable "node_desired_size" {
  description = "노드 그룹 원하는 노드 수"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "노드 그룹 최소 노드 수"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "노드 그룹 최대 노드 수"
  type        = number
  default     = 5
}

variable "db_name" {
  description = "RDS 데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "RDS 마스터 사용자명"
  type        = string
}

variable "db_password" {
  description = "RDS 마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis 인증 비밀번호"
  type        = string
  sensitive   = true
}

variable "redis_business_password" {
  description = "Redis Business 인증 비밀번호"
  type        = string
  sensitive   = true
}

variable "kc_admin_password" {
  description = "Keycloak 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "keycloak_client_secret" {
  description = "Keycloak BFF 클라이언트 시크릿"
  type        = string
  sensitive   = true
}

# s3_access_key / s3_secret_key 는 iam.tf의 aws_iam_access_key.s3_app_key 에서 자동 생성됨

variable "internal_api_key" {
  description = "내부 서비스 간 인증 API Key"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth2 Client ID"
  type        = string
  default     = ""
}

variable "google_client_secret" {
  description = "Google OAuth2 Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kakao_client_id" {
  description = "Kakao OAuth2 Client ID"
  type        = string
  default     = ""
}

variable "kakao_client_secret" {
  description = "Kakao OAuth2 Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "naver_client_id" {
  description = "Naver OAuth2 Client ID"
  type        = string
  default     = ""
}

variable "naver_client_secret" {
  description = "Naver OAuth2 Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "encryption_aes_key" {
  description = "AES 암호화 키 (Base64)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "encryption_hmac_key" {
  description = "HMAC 서명 키 (Base64)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "toss_client_key" {
  description = "Toss Payments Client Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "toss_secret_key" {
  description = "Toss Payments Secret Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "smtp_user" {
  description = "SMTP 사용자명 (이메일)"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP 비밀번호"
  type        = string
  sensitive   = true
  default     = ""
}
