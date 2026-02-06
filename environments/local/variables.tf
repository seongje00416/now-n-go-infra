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
  default     = ["dev", "staging", "monitoring"]    # 이 경우 기본 값으로 리스트 형태를 제공
}