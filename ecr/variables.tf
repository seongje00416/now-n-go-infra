variable "cluster_name" {
  description = "EKS 클러스터 이름 (ECR 레포지토리 prefix로 사용)"
  type        = string
  default     = "now-n-go-cluster"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}
