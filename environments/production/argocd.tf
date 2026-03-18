resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "5.51.6"

  create_namespace = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  depends_on = [aws_eks_node_group.main]
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
      name: argocd-app
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/MZC-Final-Project/mzc-final-project-argo.git
        targetRevision: main
        path: prod
      destination:
        server: https://kubernetes.default.svc
        namespace: prod
      syncPolicy:
        automated:
          prune: true
          selfHeal: true                  
        syncOptions:
        - CreateNamespace=true
  YAML

  depends_on = [helm_release.argocd, kubectl_manifest.github_repo_secret]
}