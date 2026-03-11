variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "nowandgo"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "nowandgo"
}

variable "db_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "redis_auth_password" {
  description = "Auth token for the Redis auth cluster"
  type        = string
  sensitive   = true
}

variable "redis_business_password" {
  description = "Auth token for the Redis business cluster"
  type        = string
  sensitive   = true
}

variable "encryption_aes_key" {
  description = "AES-256-GCM key used by common-crypto module"
  type        = string
  sensitive   = true
}

variable "encryption_hmac_key" {
  description = "HMAC-SHA256 key used by common-crypto module"
  type        = string
  sensitive   = true
}

variable "internal_api_key" {
  description = "Shared secret for internal service-to-service API calls (X-Internal-Api-Key header)"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Admin password for the Keycloak instance"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Route53 domain name if available (leave empty to skip DNS/ACM resources)"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "nowandgo"
    ManagedBy = "terraform"
  }
}
