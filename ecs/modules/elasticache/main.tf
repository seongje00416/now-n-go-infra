# ============================================================
# ElastiCache Redis 모듈
# - auth 용 Redis (세션/토큰 저장)
# - business 용 Redis (도메인 캐시/분산 락)
# - Redis 7.x, transit 암호화 활성화
# ============================================================

# ------------------------------
# ElastiCache 서브넷 그룹
# ------------------------------
resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-redis-subnet-group"
  description = "${var.project_name} ${var.environment} ElastiCache 서브넷 그룹 (프라이빗 데이터 서브넷)"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ------------------------------
# auth Redis Replication Group
# - 게이트웨이 세션, 토큰, 인증 캐시 전용
# - transit 암호화 + auth 토큰 인증
# ------------------------------
resource "aws_elasticache_replication_group" "auth" {
  replication_group_id = "${var.project_name}-${var.environment}-redis-auth"
  description          = "${var.project_name} ${var.environment} auth 전용 Redis (세션/토큰)"

  # 엔진 설정
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_clusters   = 1
  port                 = 6379

  # 네트워크 설정
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = var.security_group_ids

  # 보안 설정
  transit_encryption_enabled = true
  auth_token                 = var.auth_password

  # 유지보수 설정
  maintenance_window       = "sun:05:00-sun:06:00"
  snapshot_retention_limit = 1
  snapshot_window          = "04:00-05:00"

  # 마이너 버전 자동 업그레이드
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-auth"
    Project     = var.project_name
    Environment = var.environment
    Role        = "auth"
  }
}

# ------------------------------
# business Redis Replication Group
# - 도메인 서비스 캐시, 분산 락, Rate Limiter 전용
# - transit 암호화 + auth 토큰 인증
# ------------------------------
resource "aws_elasticache_replication_group" "business" {
  replication_group_id = "${var.project_name}-${var.environment}-redis-business"
  description          = "${var.project_name} ${var.environment} business 전용 Redis (도메인 캐시/분산 락)"

  # 엔진 설정
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_clusters   = 1
  port                 = 6379

  # 네트워크 설정
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = var.security_group_ids

  # 보안 설정
  transit_encryption_enabled = true
  auth_token                 = var.business_password

  # 유지보수 설정
  maintenance_window       = "sun:06:00-sun:07:00"
  snapshot_retention_limit = 1
  snapshot_window          = "05:00-06:00"

  # 마이너 버전 자동 업그레이드
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-business"
    Project     = var.project_name
    Environment = var.environment
    Role        = "business"
  }
}
