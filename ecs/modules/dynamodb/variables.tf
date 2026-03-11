# ============================================================
# DynamoDB 모듈 변수 정의
# ============================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍 prefix로 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
}
