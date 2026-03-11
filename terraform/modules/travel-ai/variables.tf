variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "db_host" {
  description = "PostgreSQL 호스트 주소"
  type        = string
}

variable "db_port" {
  description = "PostgreSQL 포트"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_user" {
  description = "데이터베이스 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 패스워드"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "Lambda 함수가 배포될 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Lambda 함수가 배포될 서브넷 ID 목록"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "RDS 인스턴스의 보안 그룹 ID"
  type        = string
}

variable "llm_model_id" {
  description = "Bedrock LLM 모델 ID"
  type        = string
  default     = "amazon.nova-pro-v1:0"
}
