# ============================================================
# DynamoDB 모듈
# - orders 테이블: 주문 이벤트 소싱 / 빠른 단건 조회용
# - PAY_PER_REQUEST 과금 (트래픽 변동 대응)
# - Point-in-time recovery 활성화
# ============================================================

# ------------------------------
# orders 테이블
# - Partition key: id (N) — 주문 식별자
# ------------------------------
resource "aws_dynamodb_table" "orders" {
  name         = "${var.project_name}-${var.environment}-orders"
  billing_mode = "PAY_PER_REQUEST"

  # 파티션 키 설정
  hash_key = "id"

  attribute {
    name = "id"
    type = "N"
  }

  # Point-in-time recovery (데이터 보호)
  point_in_time_recovery {
    enabled = true
  }

  # 저장 암호화 (AWS 관리형 키)
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-orders"
    Project     = var.project_name
    Environment = var.environment
  }
}
