# terraform.tfvars : 각 변수에 지정할 실제 값들 정의
# == variables.tf는 변수를 정의하는 파일, terraform.tfvars는 변수에 값을 할당하는 파일

# 변수 명 = "값"
#  변수 명은 variables.tf 파일에 정의된 변수 이름과 일치해야 함
cluster_name = "local-dev"
namespaces   = ["dev", "staging", "monitoring", "logging"]      # 리스트의 경우, 내부 값을 개수가 꼭 기본 값과 일치할 필요 없음