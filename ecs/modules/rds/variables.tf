# ============================================================
# RDS 모듈 변수 정의
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
  description = "RDS를 배치할 프라이빗 데이터 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_ids" {
  description = "RDS 인스턴스에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "db_name" {
  description = "생성할 데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "RDS 마스터 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "RDS 마스터 사용자 비밀번호 (Secrets Manager 참조 권장)"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "skip_final_snapshot" {
  description = "인스턴스 삭제 시 최종 스냅샷 생략 여부 (개발 환경: true, 운영 환경: false 권장)"
  type        = bool
  default     = true
}
