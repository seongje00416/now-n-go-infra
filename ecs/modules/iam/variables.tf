variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (예: production, staging)"
  type        = string
}

variable "s3_bucket_arns" {
  description = "auth-task-role이 접근할 S3 버킷 ARN 목록 (user-profiles 버킷 등)"
  type        = list(string)
  default     = []
}

variable "dynamodb_table_arn" {
  description = "booking-task-role이 접근할 DynamoDB 테이블 ARN"
  type        = string
  default     = "*"
}

variable "opensearch_domain_arn" {
  description = "travel-ai-task-role이 접근할 OpenSearch 도메인 ARN"
  type        = string
  default     = "*"
}
