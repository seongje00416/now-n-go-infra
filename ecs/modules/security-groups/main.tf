locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# ALB 보안 그룹
#  인터넷에서 HTTPS(443), HTTP(80) 트래픽을 수신
#  HTTP → HTTPS 리다이렉트를 위해 80도 허용
# ============================================================
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB 보안 그룹 — 인터넷 인바운드 허용"
  vpc_id      = var.vpc_id

  # HTTPS 트래픽 허용
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP 트래픽 허용 (HTTPS 리다이렉트용)
  ingress {
    description = "HTTP from internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 전체 허용
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-alb-sg"
    managed-by = "terraform"
  }
}

# ============================================================
# ECS 서비스 보안 그룹
#  ALB에서 들어오는 트래픽 허용
#  서비스 간 통신(self-referencing)도 허용
# ============================================================
resource "aws_security_group" "ecs_service" {
  name        = "${local.name_prefix}-ecs-service-sg"
  description = "ECS Fargate 서비스 보안 그룹 — ALB 및 서비스 간 통신 허용"
  vpc_id      = var.vpc_id

  # ALB에서 오는 모든 트래픽 허용
  ingress {
    description     = "All traffic from ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  # 아웃바운드 전체 허용 (ECR, S3, 외부 API 등)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-ecs-service-sg"
    managed-by = "terraform"
  }
}

# ECS 서비스 간 통신 (self-referencing rule)
#  별도 리소스로 분리하여 순환 참조 방지
resource "aws_security_group_rule" "ecs_service_self" {
  description              = "Allow intra-service traffic (service-to-service)"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.ecs_service.id
  source_security_group_id = aws_security_group.ecs_service.id
}

# ============================================================
# RDS 보안 그룹 (PostgreSQL)
#  ECS 서비스에서만 PostgreSQL 포트 접근 허용
# ============================================================
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS PostgreSQL 보안 그룹 — ECS 서비스에서만 접근 허용"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS services"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-rds-sg"
    managed-by = "terraform"
  }
}

# ============================================================
# ElastiCache(Redis) 보안 그룹
#  ECS 서비스에서만 Redis 포트 접근 허용
# ============================================================
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "ElastiCache Redis 보안 그룹 — ECS 서비스에서만 접근 허용"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from ECS services"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-redis-sg"
    managed-by = "terraform"
  }
}

# ============================================================
# MSK(Kafka) 보안 그룹
#  ECS 서비스에서 Kafka 브로커 포트 접근 허용
#  9092: PLAINTEXT, 9098: SASL_SSL
# ============================================================
resource "aws_security_group" "msk" {
  name        = "${local.name_prefix}-msk-sg"
  description = "MSK Kafka 보안 그룹 — ECS 서비스에서만 접근 허용"
  vpc_id      = var.vpc_id

  # Kafka PLAINTEXT 포트
  ingress {
    description     = "Kafka PLAINTEXT from ECS services"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  # Kafka SASL_SSL 포트
  ingress {
    description     = "Kafka SASL_SSL from ECS services"
    from_port       = 9098
    to_port         = 9098
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-msk-sg"
    managed-by = "terraform"
  }
}

# ============================================================
# OpenSearch 보안 그룹
#  ECS 서비스에서 HTTPS(443)로만 접근 허용
#  RAG/하이브리드 검색 서비스용
# ============================================================
resource "aws_security_group" "opensearch" {
  name        = "${local.name_prefix}-opensearch-sg"
  description = "OpenSearch 보안 그룹 — ECS 서비스에서만 HTTPS 접근 허용"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from ECS services"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-opensearch-sg"
    managed-by = "terraform"
  }
}

# ============================================================
# Keycloak 보안 그룹
#  ECS 서비스(Gateway)에서 Keycloak HTTP 포트 접근 허용
# ============================================================
resource "aws_security_group" "keycloak" {
  name        = "${local.name_prefix}-keycloak-sg"
  description = "Keycloak 보안 그룹 — ECS 서비스에서만 접근 허용"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Keycloak HTTP from ECS services"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-keycloak-sg"
    managed-by = "terraform"
  }
}
