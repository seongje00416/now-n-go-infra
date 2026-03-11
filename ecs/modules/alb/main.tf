# =============================================================================
# ALB (Application Load Balancer) 모듈
# 인터넷 facing ALB를 생성하고 gateway-service로 트래픽을 라우팅한다.
# HTTP(80) → HTTPS(443) 리다이렉트, ACM 인증서 선택적 지원.
# =============================================================================

locals {
  # ACM 인증서 ARN이 제공된 경우 HTTPS 리스너를 생성한다
  use_https = var.certificate_arn != ""
}

# -----------------------------------------------------------------------------
# ALB 본체 — 인터넷 facing, 퍼블릭 서브넷 배포
# -----------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  # 액세스 로그는 별도 S3 버킷 설정 후 활성화 권장
  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Project     = var.project_name
    Environment = var.environment
    Module      = "alb"
  }
}

# -----------------------------------------------------------------------------
# gateway-service 타겟 그룹
# Fargate awsvpc 모드이므로 target_type = "ip"
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "gateway" {
  name                 = "${var.project_name}-${var.environment}-gateway-tg"
  port                 = 8443
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip" # Fargate awsvpc 필수

  # 등록 해제 지연: 배포 속도 개선을 위해 30초로 단축
  deregistration_delay = 30

  health_check {
    path                = "/actuator/health"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-gateway-tg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "gateway-service"
  }
}

# -----------------------------------------------------------------------------
# HTTP(80) 리스너 — HTTPS로 영구 리다이렉트
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# HTTPS(443) 리스너 — ACM 인증서 사용 (인증서가 없으면 생성 생략)
# 기본 액션: 404 고정 응답 (리스너 룰에서 게이트웨이로 포워딩)
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  count = local.use_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  # 기본 액션: 매칭되는 룰이 없을 경우 404 반환
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\": \"Not Found\"}"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-https-listener"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# HTTPS 리스너 룰 — 모든 트래픽을 gateway-service 타겟 그룹으로 포워딩
# -----------------------------------------------------------------------------
resource "aws_lb_listener_rule" "gateway" {
  count = local.use_https ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-gateway-rule"
    Project     = var.project_name
    Environment = var.environment
  }
}
