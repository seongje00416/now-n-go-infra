# ============================================================
# OpenSearch 모듈 변수 정의
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
  description = "OpenSearch를 배치할 프라이빗 데이터 서브넷 ID 목록 (최소 2개, AZ별 1개)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "OpenSearch 도메인에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "instance_type" {
  description = "OpenSearch 노드 인스턴스 타입"
  type        = string
  default     = "t3.small.search"
}

variable "volume_size" {
  description = "OpenSearch EBS 볼륨 크기 (GB)"
  type        = number
  default     = 50
}
