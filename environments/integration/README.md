## EKS Integration Test Stage

### 사용 방법
```
# 1. 클러스터 + 노드 그룹 먼저 생성
terraform apply -target=aws_eks_cluster.main
terraform apply -target=aws_eks_node_group.main

# 2. 애드온 설치
terraform apply -target=aws_eks_addon.ebs_csi_driver
terraform apply -target=aws_eks_addon.coredns

# 3. 나머지 전부
terraform apply

# 4. kubectl 컨텍스트 연결
aws eks update-kubeconfig --region ap-northeast-2 --name team2-integration-stage
```