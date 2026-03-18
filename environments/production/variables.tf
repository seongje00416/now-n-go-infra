variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "now-n-go-cluster"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "node_instance_type" {
  description = "노드 그룹 EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "노드 그룹 원하는 노드 수"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "노드 그룹 최소 노드 수"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "노드 그룹 최대 노드 수"
  type        = number
  default     = 3
}

variable "db_name" {
  description = "RDS 데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "RDS 마스터 사용자명"
  type        = string
}

variable "db_password" {
  description = "RDS 마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub 사용자명"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}