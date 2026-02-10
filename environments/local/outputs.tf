# outputs.tf : 인프라가 생성되면 받을 출력 값들 정의
#  사용자가 직접 인프라를 생성하는 것이 아니기 때문에 만들어지는 인프라의 엔드포인트, CDN 등과 같은 값을 받기 위해 설정

# output "값 이름" : 출력 값에 대한 정의
output "cluster_name" {
  description = "Kind 클러스터 이름"
  value       = kind_cluster.default.name           # 출력하고자 하는 값
}

output "cluster_endpoint" {
  description = "Kubernetes API 엔드포인트"
  value       = kind_cluster.default.endpoint
}

output "kubeconfig" {
  description = "Kubeconfig 파일 내용"
  value       = kind_cluster.default.kubeconfig
  sensitive   = true
}

output "ingress_ip" {
  description = "Ingress Controller IP"
  value       = "localhost"
}

output "argocd_server_url" {
  description = "ArgoCD 서버 URL"
  value       = "http://argocd.local (또는 NodePort 사용)"
}

output "argocd_initial_password_command" {
  description = "ArgoCD 초기 admin 비밀번호 확인 명령어"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}