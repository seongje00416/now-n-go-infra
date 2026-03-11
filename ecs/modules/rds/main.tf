# ============================================================
# RDS PostgreSQL 16 모듈
# - Primary 인스턴스 + Read Replica
# - 프라이빗 데이터 서브넷에 배치
# - 스토리지 암호화 활성화
# ============================================================

# ------------------------------
# DB 서브넷 그룹
# ------------------------------
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-rds-subnet-group"
  description = "${var.project_name} ${var.environment} RDS 서브넷 그룹 (프라이빗 데이터 서브넷)"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ------------------------------
# DB 파라미터 그룹
# - 연결 로깅 활성화
# - pg_stat_statements 프리로드
# ------------------------------
resource "aws_db_parameter_group" "this" {
  name        = "${var.project_name}-${var.environment}-pg16"
  family      = "postgres16"
  description = "${var.project_name} ${var.environment} PostgreSQL 16 파라미터 그룹"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-pg16"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ------------------------------
# RDS Primary 인스턴스
# - PostgreSQL 16
# - 100GB gp3 스토리지
# - 스토리지 암호화 활성화
# - 백업 보존 7일
# ------------------------------
resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-${var.environment}-postgres-primary"

  # 엔진 설정
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class

  # 스토리지 설정
  allocated_storage     = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # DB 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # 파라미터 그룹
  parameter_group_name = aws_db_parameter_group.this.name

  # 가용성 설정 (비용 최적화 — 필요 시 true로 전환)
  multi_az = false

  # 백업 설정
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # 스냅샷 설정 (개발 환경용 — 운영 시 false 권장)
  skip_final_snapshot = var.skip_final_snapshot

  # 마이너 버전 자동 업그레이드
  auto_minor_version_upgrade = true

  # 삭제 보호 (운영 시 true 권장)
  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-primary"
    Project     = var.project_name
    Environment = var.environment
    Role        = "primary"
  }
}

# ------------------------------
# RDS Read Replica
# - Primary와 동일한 인스턴스 클래스
# - 읽기 전용 트래픽 오프로드
# ------------------------------
resource "aws_db_instance" "replica" {
  identifier = "${var.project_name}-${var.environment}-postgres-replica"

  # 레플리카 소스 지정
  replicate_source_db = aws_db_instance.primary.identifier

  # 인스턴스 설정
  instance_class = var.instance_class

  # 네트워크 설정
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # 파라미터 그룹
  parameter_group_name = aws_db_parameter_group.this.name

  # 레플리카는 백업 비활성화 (Primary에서 관리)
  backup_retention_period = 0

  # 스냅샷 설정
  skip_final_snapshot = var.skip_final_snapshot

  # 마이너 버전 자동 업그레이드
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-replica"
    Project     = var.project_name
    Environment = var.environment
    Role        = "replica"
  }
}
