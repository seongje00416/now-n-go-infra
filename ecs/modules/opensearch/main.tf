# ============================================================
# OpenSearch 모듈
# - 도메인: nowandgo-search
# - 하이브리드 검색 (키워드 + 벡터) 및 RAG 인덱스 제공
# - 2노드 Zone Awareness (고가용성)
# ============================================================

# ------------------------------
# OpenSearch 도메인
# - OpenSearch 2.11
# - gp3 EBS, Zone Awareness 2-AZ
# - VPC 내 프라이빗 배치
# ------------------------------
resource "aws_opensearch_domain" "this" {
  domain_name    = "nowandgo-search"
  engine_version = "OpenSearch_2.11"

  # 클러스터 설정
  cluster_config {
    instance_type          = var.instance_type
    instance_count         = 2
    zone_awareness_enabled = true

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  # EBS 스토리지 설정
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.volume_size
  }

  # VPC 배치 설정 (프라이빗 데이터 서브넷)
  vpc_options {
    subnet_ids         = slice(var.subnet_ids, 0, 2)
    security_group_ids = var.security_group_ids
  }

  # 고급 옵션
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  # 액세스 정책: VPC 내부에서만 접근 허용
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "es:*"
        Resource  = "arn:aws:es:*:*:domain/nowandgo-search/*"
      }
    ]
  })

  # 저장 암호화
  encrypt_at_rest {
    enabled = true
  }

  # 노드 간 전송 암호화
  node_to_node_encryption {
    enabled = true
  }

  # HTTPS 강제
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Name        = "nowandgo-search"
    Project     = var.project_name
    Environment = var.environment
  }
}
