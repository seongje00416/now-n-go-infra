# ============================================================
# S3 버킷
# ============================================================
resource "aws_s3_bucket" "main" {
  bucket = "${var.cluster_name}-bucket"

  tags = {
    Name       = "${var.cluster_name}-bucket"
    managed-by = "terraform"
  }
}

# 외부 공개 접근 전면 차단
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 버킷에 저장되는 객체 서버 측 암호화 (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 버전 관리 활성화 (객체 덮어쓰기/삭제 시 이전 버전 보존)
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}
