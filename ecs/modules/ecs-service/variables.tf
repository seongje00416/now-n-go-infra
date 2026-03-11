# =============================================================================
# ECS 서비스 모듈 — 입력 변수
# =============================================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍 접두사로 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# 서비스 식별
# -----------------------------------------------------------------------------

variable "service_name" {
  description = "서비스 이름 (예: gateway-service, user-command-service)"
  type        = string
}

variable "cluster_id" {
  description = "ECS 클러스터 ID"
  type        = string
}

# -----------------------------------------------------------------------------
# 컨테이너 설정
# -----------------------------------------------------------------------------

variable "container_image" {
  description = "컨테이너 이미지 URI (ECR URL 포함)"
  type        = string
}

variable "container_port" {
  description = "컨테이너가 리스닝하는 HTTP 포트"
  type        = number
}

variable "grpc_port" {
  description = "gRPC 포트 (사용하지 않는 경우 null)"
  type        = number
  default     = null
}

variable "cpu" {
  description = "Fargate 태스크 CPU 단위 (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate 태스크 메모리 (MiB)"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "실행할 태스크 수 (CI/CD에서 ignore_changes 적용됨)"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# 네트워크 설정
# -----------------------------------------------------------------------------

variable "subnet_ids" {
  description = "ECS 태스크를 배포할 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_ids" {
  description = "ECS 태스크에 연결할 보안 그룹 ID 목록"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# IAM 역할
# -----------------------------------------------------------------------------

variable "task_execution_role_arn" {
  description = "ECS 태스크 실행 역할 ARN (ECR pull, CloudWatch Logs 권한)"
  type        = string
}

variable "task_role_arn" {
  description = "ECS 태스크 역할 ARN (애플리케이션 AWS 서비스 접근 권한)"
  type        = string
}

# -----------------------------------------------------------------------------
# 서비스 검색
# -----------------------------------------------------------------------------

variable "service_discovery_namespace_id" {
  description = "Cloud Map 프라이빗 DNS 네임스페이스 ID"
  type        = string
}

# -----------------------------------------------------------------------------
# 환경 변수 및 시크릿
# -----------------------------------------------------------------------------

variable "environment_variables" {
  description = "컨테이너에 주입할 환경 변수 맵 (평문)"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets Manager에서 주입할 시크릿 맵 (환경변수명 → ARN)"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# 헬스체크
# -----------------------------------------------------------------------------

variable "health_check_path" {
  description = "컨테이너 헬스체크 경로 (Spring Boot: /actuator/health)"
  type        = string
  default     = "/actuator/health"
}

# -----------------------------------------------------------------------------
# ALB 연동 (선택)
# -----------------------------------------------------------------------------

variable "enable_alb" {
  description = "ALB 타겟 그룹 연결 여부 (gateway-service 등 외부 노출 서비스에만 true)"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "연결할 ALB 타겟 그룹 ARN (enable_alb = true 일 때 필수)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# 로깅
# -----------------------------------------------------------------------------

variable "log_group_name" {
  description = "CloudWatch 로그 그룹 이름"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전 (CloudWatch Logs 드라이버에 사용)"
  type        = string
}
