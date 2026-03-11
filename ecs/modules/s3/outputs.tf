# ============================================================
# S3 모듈 출력값
# ============================================================

output "user_profiles_bucket_arn" {
  description = "user-profiles S3 버킷 ARN"
  value       = aws_s3_bucket.user_profiles.arn
}

output "user_profiles_bucket_name" {
  description = "user-profiles S3 버킷 이름"
  value       = aws_s3_bucket.user_profiles.bucket
}

output "media_bucket_arn" {
  description = "nowandgo-media S3 버킷 ARN"
  value       = aws_s3_bucket.media.arn
}

output "media_bucket_name" {
  description = "nowandgo-media S3 버킷 이름"
  value       = aws_s3_bucket.media.bucket
}
