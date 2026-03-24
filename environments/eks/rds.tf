# ============================================================
# RDS 서브넷 그룹
#  RDS는 고가용성을 위해 2개 이상의 AZ에 걸친 서브넷 그룹이 필요
#  EKS 노드와 같은 프라이빗 서브넷에 배치
# ============================================================
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name       = "${var.cluster_name}-db-subnet-group"
    managed-by = "terraform"
  }
}

# ============================================================
# RDS 보안 그룹
#  EKS 노드(VPC 내부)에서 오는 5432 포트만 허용
# ============================================================
resource "aws_security_group" "rds" {
  name   = "${var.cluster_name}-rds-sg"
  vpc_id = aws_vpc.main.id

  # VPC 내부에서 오는 PostgreSQL 접근만 허용
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # 아웃바운드는 전체 허용 (AWS 업데이트, 패치 등)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.cluster_name}-rds-sg"
    managed-by = "terraform"
  }
}

# ============================================================
# RDS 인스턴스 (PostgreSQL)
# ============================================================
resource "aws_db_instance" "main" {
  identifier = "${var.cluster_name}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.large"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  allocated_storage     = 20       # 초기 스토리지 (GB)
  max_allocated_storage = 100      # 자동 스케일링 상한선 (GB)
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false      # 운영 환경에서는 true 권장
  publicly_accessible = false      # 프라이빗 서브넷 전용

  backup_retention_period = 7
  backup_window           = "19:00-20:00"   # KST 새벽 4-5시

  maintenance_window = "Sun:20:00-Sun:21:00"

  # terraform destroy 시 스냅샷 없이 삭제 (운영 시 false 권장)
  skip_final_snapshot = true

  tags = {
    Name       = "${var.cluster_name}-db"
    managed-by = "terraform"
  }
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = aws_db_instance.main.address
}
