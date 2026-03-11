# =============================================================================
# 모니터링 모듈
# CloudWatch 로그 그룹, SNS 알림 토픽, CloudWatch 알람, 대시보드를 생성한다.
# =============================================================================

locals {
  # ALB ARN에서 suffix 추출 (알람의 dimensions에 사용)
  # 예: arn:aws:elasticloadbalancing:...:loadbalancer/app/name/id → app/name/id
  alb_arn_suffix = var.alb_arn != "" ? regex("loadbalancer/(.+)$", var.alb_arn)[0] : ""
}

# -----------------------------------------------------------------------------
# CloudWatch 로그 그룹 — 서비스별 로그 수집
# for_each로 service_names 목록에서 동적 생성
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "services" {
  for_each = toset(var.service_names)

  name              = "/ecs/nowandgo/${each.key}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "/ecs/nowandgo/${each.key}"
    Project     = var.project_name
    Environment = var.environment
    Service     = each.key
    Module      = "monitoring"
  }
}

# -----------------------------------------------------------------------------
# SNS 토픽 — ECS/ALB 알람 수신처
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "nowandgo-ecs-alerts"

  tags = {
    Name        = "nowandgo-ecs-alerts"
    Project     = var.project_name
    Environment = var.environment
    Module      = "monitoring"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch 알람 — ALB 5xx 오류율 (1분 내 5건 초과 시 알림)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  count = var.alb_arn != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "ALB 5xx 오류가 1분 내 5건을 초과했습니다."
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Module      = "monitoring"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch 알람 — ALB 타겟 응답 시간 (평균 5초 초과 시 알림)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count = var.alb_arn != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "ALB 타겟 평균 응답 시간이 5초를 초과했습니다."
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Module      = "monitoring"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch 대시보드 — ECS 및 ALB 주요 지표 한눈에 보기
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "nowandgo-ecs-overview"

  dashboard_body = jsonencode({
    widgets = [
      # ECS CPU 사용률
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU 사용률 (%)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = var.cluster_name != "" ? [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, { "stat" : "Average", "label" : "CPU 평균" }]
          ] : []
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      # ECS 메모리 사용률
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS 메모리 사용률 (%)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = var.cluster_name != "" ? [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, { "stat" : "Average", "label" : "메모리 평균" }]
          ] : []
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      # ALB 요청 수
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB 요청 수 (1분)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = var.alb_arn != "" ? [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_arn_suffix, { "stat" : "Sum", "label" : "요청 수" }]
          ] : []
        }
      },
      # ALB 5xx 오류 수
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB 5xx 오류 수 (1분)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = var.alb_arn != "" ? [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.alb_arn_suffix, { "stat" : "Sum", "label" : "5xx 오류" }]
          ] : []
        }
      },
      # RDS CPU 사용률
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS CPU 사용률 (%)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "CPUUtilization", { "stat" : "Average", "label" : "RDS CPU 평균" }]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      }
    ]
  })
}
