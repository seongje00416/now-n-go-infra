# ============================================================
# S3 모듈
# - user-profiles 버킷: 사용자 프로필 이미지 (퍼블릭 접근 차단)
# - nowandgo-media 버킷: 미디어 컨텐츠 (퍼블릭 읽기 허용)
# - 버전 관리 및 서버 사이드 암호화 활성화
# ============================================================

# ------------------------------
# user-profiles 버킷
# - 프로필 이미지 등 사용자 데이터 저장
# - 퍼블릭 접근 완전 차단 (서비스 내부 Presigned URL로 접근)
# ------------------------------
resource "aws_s3_bucket" "user_profiles" {
  bucket = "${var.project_name}-user-profiles"

  tags = {
    Name        = "${var.project_name}-user-profiles"
    Project     = var.project_name
    Environment = var.environment
  }
}

# 버전 관리 활성화
resource "aws_s3_bucket_versioning" "user_profiles" {
  bucket = aws_s3_bucket.user_profiles.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 서버 사이드 암호화 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "user_profiles" {
  bucket = aws_s3_bucket.user_profiles.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 퍼블릭 접근 완전 차단
resource "aws_s3_bucket_public_access_block" "user_profiles" {
  bucket = aws_s3_bucket.user_profiles.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------
# nowandgo-media 버킷
# - 여행 상품 이미지, 미디어 컨텐츠 저장
# - 퍼블릭 읽기 허용 (CDN 원본 또는 직접 서빙용)
# ------------------------------
resource "aws_s3_bucket" "media" {
  bucket = "${var.project_name}-nowandgo-media"

  tags = {
    Name        = "${var.project_name}-nowandgo-media"
    Project     = var.project_name
    Environment = var.environment
  }
}

# 버전 관리 활성화
resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 서버 사이드 암호화 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 퍼블릭 접근 설정 (ACL은 차단, 버킷 정책으로만 퍼블릭 읽기 허용)
resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# 퍼블릭 읽기 버킷 정책 (GET 허용)
resource "aws_s3_bucket_policy" "media_public_read" {
  bucket     = aws_s3_bucket.media.id
  depends_on = [aws_s3_bucket_public_access_block.media]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.media.arn}/*"
      }
    ]
  })
}
