# =============================================================================
# ALB 모듈 — 입력 변수
# =============================================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍 접두사로 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ALB와 타겟 그룹을 배포할 VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB를 배포할 퍼블릭 서브넷 ID 목록 (멀티 AZ 권장)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "ALB에 연결할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM SSL 인증서 ARN (비어있으면 HTTP 전용 모드로 동작)"
  type        = string
  default     = ""
}
