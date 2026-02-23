variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "team2-integration-stage"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"   # 서울 리전
}

variable "namespaces" {
  description = "생성할 네임스페이스 목록"
  type        = list(string)
  default     = ["integration", "monitoring"]
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

variable "redis_password" {
  description = "Redis 비밀번호"
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