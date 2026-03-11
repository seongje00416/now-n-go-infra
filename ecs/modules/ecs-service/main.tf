# =============================================================================
# ECS 서비스 모듈 (재사용 가능)
# 서비스마다 한 번씩 호출되며, 태스크 정의 + ECS 서비스 + Cloud Map 서비스 검색을 생성한다.
# CI/CD 파이프라인에서 태스크 정의와 desired_count를 직접 업데이트할 수 있도록
# lifecycle ignore_changes를 적용한다.
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch 로그 그룹 — 태스크 로그 수집
# -----------------------------------------------------------------------------
locals {
  # gRPC 포트가 지정된 경우 portMappings에 추가
  grpc_port_mapping = var.grpc_port != null ? [
    {
      containerPort = var.grpc_port
      protocol      = "tcp"
    }
  ] : []

  # secrets 맵을 ECS 컨테이너 정의 형식으로 변환 (name + valueFrom)
  secrets_list = [
    for env_name, arn in var.secrets : {
      name      = env_name
      valueFrom = arn
    }
  ]
}

# -----------------------------------------------------------------------------
# ECS 태스크 정의
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true

      # 포트 매핑: HTTP/gRPC 포트
      portMappings = concat(
        [
          {
            containerPort = var.container_port
            protocol      = "tcp"
          }
        ],
        local.grpc_port_mapping
      )

      # 서비스별 환경 변수
      environment = [
        for k, v in var.environment_variables : {
          name  = k
          value = v
        }
      ]

      # Secrets Manager에서 주입하는 민감한 환경 변수
      secrets = local.secrets_list

      # CloudWatch Logs 드라이버 설정
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.service_name
        }
      }

      # 헬스체크: Spring Boot Actuator 엔드포인트 확인
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.service_name}"
    Project     = var.project_name
    Environment = var.environment
    Service     = var.service_name
    Module      = "ecs-service"
  }
}

# -----------------------------------------------------------------------------
# Cloud Map 서비스 검색 — 서비스 간 내부 DNS 기반 통신
# -----------------------------------------------------------------------------
resource "aws_service_discovery_service" "this" {
  name = var.service_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      type = "A"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }

  # ECS 서비스 헬스체크와 연동 (AWS가 항상 1로 고정하므로 별도 설정 불필요)
  health_check_custom_config {}


  tags = {
    Name        = var.service_name
    Project     = var.project_name
    Environment = var.environment
    Service     = var.service_name
  }
}

# -----------------------------------------------------------------------------
# ECS 서비스
# -----------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.service_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  # Fargate awsvpc 네트워크 설정: 퍼블릭 IP 비활성화 (프라이빗 서브넷 배포)
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  # Cloud Map 서비스 검색 연결
  service_registries {
    registry_arn = aws_service_discovery_service.this.arn
  }

  # ALB 연결 (enable_alb = true 인 서비스만 적용)
  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  # 배포 서킷 브레이커: 배포 실패 시 이전 버전으로 자동 롤백
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # 태그를 태스크까지 전파
  propagate_tags = "SERVICE"

  # CI/CD 파이프라인에서 desired_count와 task_definition을 직접 업데이트하므로
  # Terraform이 해당 필드 변경을 무시하도록 설정
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = {
    Name        = "${var.project_name}-${var.service_name}"
    Project     = var.project_name
    Environment = var.environment
    Service     = var.service_name
    Module      = "ecs-service"
  }

  depends_on = [aws_service_discovery_service.this]
}
