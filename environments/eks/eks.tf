# ============================================================
# EKS 클러스터 생성
# ============================================================
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"

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
#  실제 EC2 인스턴스들로 구성된 워커 노드 그룹
# ============================================================
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

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
#  EKS는 핵심 컴포넌트들을 애드온 형태로 관리
# ============================================================

# EBS CSI Driver: EBS 볼륨을 PV로 사용하기 위한 드라이버
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver,
  ]
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
# StorageClass (EBS gp3 기반)
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

# ============================================================
# prod 네임스페이스
#  EKS 클러스터 생성 직후 prod 네임스페이스를 미리 생성
# ============================================================
resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"

    labels = {
      name        = "prod"
      environment = "production"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# ============================================================
# Outputs
# ============================================================
output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 API 엔드포인트"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전"
  value       = aws_eks_cluster.main.version
}
