resource "aws_security_group" "lambda" {
  name        = "travel-ai-lambda-sg-${var.environment}"
  description = "travel-ai Lambda 함수용 보안 그룹"
  vpc_id      = var.vpc_id

  # PostgreSQL (RDS) 아웃바운드
  egress {
    description     = "PostgreSQL outbound to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.db_security_group_id]
  }

  # HTTPS 아웃바운드 (Bedrock API)
  egress {
    description = "HTTPS outbound for Bedrock API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "travel-ai-lambda-sg-${var.environment}"
    Environment = var.environment
    Module      = "travel-ai"
  }
}
