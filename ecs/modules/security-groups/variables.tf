variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: production, staging)"
  type        = string
}

variable "vpc_id" {
  description = "보안 그룹을 생성할 VPC ID"
  type        = string
}
