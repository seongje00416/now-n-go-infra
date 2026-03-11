# =============================================================================
# ECS 클러스터 모듈 — 입력 변수
# =============================================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍 접두사로 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: dev, staging, prod)"
  type        = string
}
