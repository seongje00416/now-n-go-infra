# variables.tf : 변경이 될 수 있는 값들을 변수로 정의
#  실제 값 할당은 terraform.tfvars 파일에서 이루어짐

# variable "변수 이름"  : 변수에 대한 정의를 선언하는 블록
#  다른 파일에서 해당 변수를 호출할 때는 var.변수이름 으로 호출
variable "cluster_name" {
  description = "Kind 클러스터 이름"                  # 변수에 대한 설명
  type        = string                              # 변수의 타입
  default     = "local-dev-cluster"                 # 따로 변수의 값을 지정하지 않는다면 대입할 기본 값 설정
}

variable "namespaces" {
  description = "생성할 네임스페이스 목록"
  type        = list(string)                        # 타입으로 리스트 형태를 지정할 수 있음
  default     = ["dev", "monitoring"]    # 이 경우 기본 값으로 리스트 형태를 제공
}

variable "argocd_version" {
  description = "ArgoCD Helm 차트 버전"
  type        = string
  default     = "5.51.6"
}

variable "worker_node_count" {
  description = "Worker 노드 수 (RAM 16GB 이하: 1, 32GB 이상: 2)"
  type        = number
  default     = 2
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

variable "redis_password" {
  description = "Redis 비밀번호"
  type        = string
  sensitive   = true
}