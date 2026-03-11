variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: production, staging)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.1.0.0/16"
}

variable "azs" {
  description = "사용할 가용 영역(AZ) 목록. 비어있으면 data source로 자동 조회"
  type        = list(string)
  default     = []
}
