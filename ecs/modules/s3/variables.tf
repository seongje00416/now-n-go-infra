# ============================================================
# S3 모듈 변수 정의
# ============================================================

variable "project_name" {
  description = "프로젝트 이름 (버킷 이름 prefix로 사용, 전역 유일해야 함)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
}
