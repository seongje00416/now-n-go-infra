# =============================================================================
# 모니터링 모듈 — 입력 변수
# =============================================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍 접두사로 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: dev, staging, prod)"
  type        = string
}

variable "service_names" {
  description = "CloudWatch 로그 그룹을 생성할 서비스 이름 목록"
  type        = list(string)
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보존 기간 (일)"
  type        = number
  default     = 30
}

variable "alb_arn" {
  description = "ALB ARN (알람 및 대시보드 ALB 지표에 사용, 비어있으면 ALB 알람 생략)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "ECS 클러스터 이름 (대시보드 ECS 지표에 사용, 비어있으면 ECS 지표 생략)"
  type        = string
  default     = ""
}
