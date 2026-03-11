# ============================================================
# ElastiCache 모듈 변수 정의
# ============================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍 prefix로 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
}

variable "subnet_ids" {
  description = "ElastiCache를 배치할 프라이빗 데이터 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_ids" {
  description = "ElastiCache 클러스터에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "auth_password" {
  description = "auth Redis auth 토큰 (최소 16자, 특수문자 일부 제한)"
  type        = string
  sensitive   = true
}

variable "business_password" {
  description = "business Redis auth 토큰 (최소 16자, 특수문자 일부 제한)"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "ElastiCache 노드 인스턴스 타입"
  type        = string
  default     = "cache.t3.micro"
}
