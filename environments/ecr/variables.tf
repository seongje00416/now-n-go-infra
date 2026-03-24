variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "ECR 레포지토리 prefix (e.g. now-n-go-cluster)"
  type        = string
  default     = "now-n-go-cluster"
}

variable "ecr_repositories" {
  description = "생성할 ECR 레포지토리 이름 목록 (prefix 제외)"
  type        = list(string)
}
