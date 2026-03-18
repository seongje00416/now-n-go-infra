## EKS Production Stage

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
aws eks update-kubeconfig --region ap-northeast-2 --name team2-production-stage
```

### ArgoCD 배포
ArgoCD Pod 구성 (7개)                                                                                                                
1. argocd-server                                                                                                                  
ArgoCD의 UI + API 서버입니다. 웹 브라우저로 접속하는 대시보드가 여기서 제공되고, argocd CLI 명령어도 이 서버와 통신합니다. 이
파일에서 LoadBalancer 타입으로 외부에 노출하는 대상이 바로 이 Pod입니다.

2. argocd-application-controller

GitOps의 핵심입니다. GitHub 레포(mzc-final-project-argo)에 정의된 상태와 실제 클러스터 상태를 지속적으로 비교하고, 차이가 있으면  
동기화합니다. selfHeal: true로 설정했기 때문에 누군가 클러스터를 직접 수정해도 Git 상태로 되돌립니다.

3. argocd-repo-server

Git 레포 연결 전담 서버입니다. GitHub에서 매니페스트를 내려받고, Helm/Kustomize 등을 렌더링해서 application-controller에게        
전달합니다. github_repo_secret으로 등록한 GitHub 자격증명을 이 Pod이 사용합니다.

4. argocd-redis

ArgoCD 내부 캐시입니다. 클러스터 상태, Git 레포 데이터 등을 임시로 저장해서 매번 Git/K8s API를 조회하지 않아도 되게 합니다. ArgoCD
전용으로 뜨는 Redis이며 외부에서 접근하지 않습니다.

5. argocd-dex-server

SSO(Single Sign-On) 인증 서버입니다. GitHub OAuth, Google, LDAP 등 외부 인증 연동을 담당합니다. 이 프로젝트에서 외부 SSO를        
사용하지 않는다면 뜨긴 하지만 실질적으로 사용되지는 않습니다.

6~7. argocd-notifications-controller + argocd-applicationset-controller

- notifications-controller: Slack, 이메일 등으로 동기화 성공/실패 알림을 보내는 Pod입니다.
- applicationset-controller: 여러 Application을 템플릿으로 일괄 생성하는 ApplicationSet 리소스를 처리합니다. 지금처럼
Application을 하나씩 정의하는 방식에서는 사용되지 않습니다.
