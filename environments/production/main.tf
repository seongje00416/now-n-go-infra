terraform {
  required_version = ">= 1.0"

  required_providers {
    # Kind 대신 AWS Provider 사용
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# AWS Provider 설정
provider "aws" {
  region = var.aws_region
}

# ============================================================
# IAM - EKS 클러스터 역할
#  EKS 클러스터가 AWS 서비스들을 제어할 수 있도록 권한 부여
# ============================================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  # EKS 서비스가 이 역할을 Assume(사용)할 수 있도록 설정
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# EKS 클러스터 운영에 필요한 AWS 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ============================================================
# IAM - 노드 그룹 역할
#  EC2 노드들이 AWS 서비스를 사용할 수 있도록 권한 부여
# ============================================================
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 노드 운영에 필요한 AWS 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EBS 볼륨 사용을 위한 정책 연결
resource "aws_iam_role_policy_attachment" "eks_ebs_csi_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ============================================================
# EKS 클러스터 생성
#  Kind의 kind_cluster 역할을 대체
# ============================================================
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_nat_gateway.main   # NAT GW가 준비된 후 클러스터 생성
  ]
}

# ============================================================
# EKS 노드 그룹
#  Kind의 node { role = "worker" } 역할을 대체
#  실제 EC2 인스턴스들로 구성된 워커 노드 그룹
# ============================================================
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id   # 노드는 프라이빗 서브넷에 배치

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # 노드 업데이트 시 중단 없이 진행하기 위한 설정
  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry,
  ]
}

# ============================================================
# EKS 애드온
#  Kind와 달리 EKS는 핵심 컴포넌트들을 애드온 형태로 관리
# ============================================================

# EBS CSI Driver: EBS 볼륨을 PV로 사용하기 위한 드라이버
#  Kind의 local_path_provisioner 역할을 대체
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  depends_on = [aws_eks_node_group.main]
}

# CoreDNS: 클러스터 내부 DNS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy: 노드 간 네트워크 통신
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_node_group.main]
}

# VPC CNI: Pod 네트워킹
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_node_group.main]
}

# ============================================================
# Kubernetes / Helm / Kubectl Provider 설정
#  Kind는 클러스터 생성 시 인증 정보를 직접 제공했지만
#  EKS는 AWS API를 통해 인증 정보를 가져옴
# ============================================================

# 클러스터 인증 토큰을 AWS에서 가져오는 data source
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "kubectl" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# ============================================================
# Namespace 생성 (Kind 버전과 동일)
# ============================================================
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
    labels = {
      environment = "production"
      managed-by  = "terraform"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# ============================================================
# NGINX Ingress Controller
#  Kind: NodePort + hostPort 방식
#  EKS: AWS NLB(Network Load Balancer)를 자동 생성하는 방식으로 변경
# ============================================================
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.8.3"

  create_namespace = true

  # EKS에서는 LoadBalancer 타입을 사용하면 AWS NLB가 자동 생성됨
  #  Kind에서는 로컬에 LB가 없어서 NodePort를 사용했지만
  #  EKS는 AWS가 실제 LB를 만들어주기 때문에 LoadBalancer 사용 가능
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  # AWS NLB 사용을 위한 어노테이션
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  # Kind에서 사용하던 로컬 설정들은 EKS에서 불필요하므로 제거
  # - hostPort.enabled (로컬 포트 매핑 불필요)
  # - nodeSelector.ingress-ready (Kind 전용 라벨)
  # - tolerations (Kind control-plane 전용)

  depends_on = [aws_eks_node_group.main]
}

# ============================================================
# StorageClass (EBS gp3 기반)
#  Kind의 local-storage 대신 AWS EBS를 사용
# ============================================================
resource "kubernetes_storage_class" "ebs_storage" {
  metadata {
    name = "ebs-storage"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"   # EBS CSI 드라이버 사용
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true                 # EBS는 볼륨 확장 지원

  parameters = {
    type      = "gp3"        # gp2보다 성능 좋고 저렴한 최신 타입
    encrypted = "true"       # EBS 암호화
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}