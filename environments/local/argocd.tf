# ArgoCD 설치
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "5.51.6"
  
  create_namespace = true
  
  # NodePort로 접근 가능하도록 설정
  set {
    name  = "server.service.type"
    value = "NodePort"
  }
  
  # Ingress 사용하려면 이 설정 추가
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }
  
  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.local"
  }
  
  depends_on = [
    kind_cluster.default,
    helm_release.nginx_ingress
  ]
}

# GitHub Repository 인증 정보 등록 (Private Repository이므로)
resource "kubectl_manifest" "github_repo_secret" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: github-repo
      namespace: argocd
      labels:
        argocd.argoproj.io/secret-type: repository
    stringData:
      type: git
      url: https://github.com/사용자명/my-k8s-manifests     # 자신의 Private Repository URL
      username: ${var.github_username}
      password: ${var.github_token}
  YAML
  
  depends_on = [helm_release.argocd]
}

# Github Repository와 연동을 위한 ArgoCD Application 생성
resource "kubectl_manifest" "argocd_application" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: my-app-dev      # 프로젝트 이름
      namespace: argocd
    spec:
      project: default      # 기본 프로젝트 사용
      source:
        repoURL: https://github.com/사용자명/my-k8s-manifests      # 바라볼 Github 레포지토리 URL
        targetRevision: main                                      # 브랜치 이름
        path: dev                           # 레포지토리 내 변경을 감지할 디렉토리 경로
      destination:
        server: https://kubernetes.default.svc
        namespace: dev                      # 로컬에서는 dev 네임스페이스가 기본
      syncPolicy:
        automated:                    # 자동 동작 설정
          prune: true                 # Git에서 파일 삭제시 K8s 리소스도 삭제
          selfHeal: false             # 로컬 배포 테스트를 위해 selfHeal은 비활성화
        syncOptions:
        - CreateNamespace=true
  YAML
  
  depends_on = [helm_release.argocd, kubectl_manifest.github_repo_secret]
}