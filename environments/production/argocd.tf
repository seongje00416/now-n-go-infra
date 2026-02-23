resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "5.51.6"

  create_namespace = true

  # EKS에서는 실제 도메인 + LoadBalancer 방식 사용
  #  Kind: NodePort + argocd.local (로컬 hosts 파일 편집 필요)
  #  EKS: LoadBalancer로 NLB 생성 후 실제 도메인 연결
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  # 실제 도메인으로 변경 (Route53 등에 등록된 도메인)
  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.your-domain.com"   # 실제 도메인으로 변경
  }

  # EKS 환경에서는 HTTPS 강제 리다이렉트 해제 (Ingress가 TLS 처리)
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [
    aws_eks_node_group.main,
    helm_release.nginx_ingress
  ]
}

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
      url: https://github.com/MZC-Final-Project/mzc-final-project-argo.git
      username: ${var.github_username}
      password: ${var.github_token}
  YAML

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: my-app-prod
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/MZC-Final-Project/mzc-final-project-argo.git
        targetRevision: main
        path: prod                        # EKS는 prod 디렉토리를 바라보도록 변경
      destination:
        server: https://kubernetes.default.svc
        namespace: prod
      syncPolicy:
        automated:
          prune: true
          selfHeal: true                  # EKS(운영)에서는 selfHeal 활성화
        syncOptions:
        - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd, kubectl_manifest.github_repo_secret]
}