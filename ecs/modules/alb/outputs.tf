# =============================================================================
# ALB 모듈 — 출력값
# =============================================================================

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름 (Route 53 Alias 레코드에 사용)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB 호스팅 존 ID (Route 53 Alias 레코드에 사용)"
  value       = aws_lb.this.zone_id
}

output "gateway_target_group_arn" {
  description = "gateway-service 타겟 그룹 ARN (ECS 서비스 연결용)"
  value       = aws_lb_target_group.gateway.arn
}

output "http_listener_arn" {
  description = "HTTP(80) 리스너 ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS(443) 리스너 ARN (인증서가 없으면 null)"
  value       = local.use_https ? aws_lb_listener.https[0].arn : null
}
