# =============================================================================
# ECS 클러스터 모듈
# Container Insights와 Fargate/Fargate Spot 용량 공급자를 포함한
# ECS 클러스터를 생성한다.
# =============================================================================

# -----------------------------------------------------------------------------
# ECS 클러스터 본체
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}"

  # Container Insights 활성화 — CloudWatch로 CPU/메모리 지표 수집
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    Module      = "ecs-cluster"
  }
}

# -----------------------------------------------------------------------------
# Fargate 용량 공급자 연결
# FARGATE: 안정성 우선 / FARGATE_SPOT: 비용 절감용 (최대 70% 할인)
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # 기본 전략: FARGATE weight 1 (안정적인 워크로드 우선)
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }
}
