variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 태그 및 네이밍에 사용)"
  type        = string
  default     = "mzc-final"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입 (Jenkins는 최소 t3.medium 권장)"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "루트 볼륨 크기 (GiB)"
  type        = number
  default     = 30
}

variable "allowed_cidr_blocks" {
  description = "접근 허용 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_key_pair" {
  description = "true: public_key_path로 새 키 생성 / false: existing_key_name 사용"
  type        = bool
  default     = true
}

variable "public_key_path" {
  description = "SSH 공개키 파일 경로"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "existing_key_name" {
  description = "기존 AWS Key Pair 이름 (create_key_pair = false 일 때 사용)"
  type        = string
  default     = ""
}

variable "github_username" {
  description = "GitHub 사용자명"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_be_repo_url" {
  description = "BE 레포 URL"
  type        = string
}

variable "github_fe_repo_url" {
  description = "FE 레포 URL"
  type        = string
}

variable "github_infra_repo_url" {
  description = "Infra 레포 URL (예: https://github.com/org/project-infra.git)"
  type        = string
}