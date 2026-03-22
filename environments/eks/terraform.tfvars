# 아래 값은 로컬에서 본인의 것으로 채워서 사용할 것 (절대 본인의 값이 입력된 채로 Git에 올리지 말 것.)


# RDS 설정
db_name     = "nowandgo"
db_username = "nowngo"
db_password = "nowngo1234"

# Redis
redis_password          = "-redis-secret"
redis_business_password = "-redis-biz-secret"

# Keycloak
kc_admin_password      = "admin"
keycloak_client_secret = "bff-secret-local-dev"

# S3
# s3_access_key / s3_secret_key 는 iam.tf의 aws_iam_access_key.s3_app_key 에서 자동 생성됨

# 기타
internal_api_key = "your-internal-api-key"

# OAuth (선택)
google_client_id     = ""
google_client_secret = ""
