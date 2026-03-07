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

  set {
    name  = "server.service.nodePortHttp"
    value = "30070"
  }

  set {
    name  = "server.service.nodePortHttps"
    value = "30443"
  }
  
  depends_on = [
    kind_cluster.default
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
      url: https://github.com/MZC-Final-Project/mzc-final-project-argo
      username: ${var.github_username}
      password: ${var.github_token}
  YAML

  depends_on = [helm_release.argocd]
}

# Jenkins CI/CD용 ArgoCD Application — argo 레포의 charts/ticket-service 경로 감시
resource "kubectl_manifest" "argocd_application_ci" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: my-app-ci
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/MZC-Final-Project/mzc-final-project-argo
        targetRevision: develop
        path: charts/ticket-service
        helm:
          valueFiles:
          - values.yaml
      destination:
        server: https://kubernetes.default.svc
        namespace: dev
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd, kubectl_manifest.github_repo_secret]
}