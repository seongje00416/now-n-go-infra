# ============================================================
# K8s Secret: infra-secret
#  인프라 서비스(Postgres/Redis/Keycloak)가 사용하는 시크릿
# ============================================================
resource "kubernetes_secret" "infra_secret" {
  metadata {
    name      = "infra-secret"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD       = var.db_password
    REDIS_PASSWORD          = var.redis_password
    REDIS_BUSINESS_PASSWORD = var.redis_business_password
    KC_ADMIN_PASSWORD       = var.kc_admin_password
  }

  depends_on = [kubernetes_namespace.prod]
}

# ============================================================
# K8s Secret: app-secret
#  Spring Boot 앱 서비스들이 사용하는 시크릿
# ============================================================
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  data = {
    DB_PASSWORD             = var.db_password
    REDIS_PASSWORD          = var.redis_password
    REDIS_BUSINESS_PASSWORD = var.redis_business_password
    KEYCLOAK_CLIENT_SECRET  = var.keycloak_client_secret
    S3_ACCESS_KEY           = aws_iam_access_key.s3_app_key.id
    S3_SECRET_KEY           = aws_iam_access_key.s3_app_key.secret
    INTERNAL_API_KEY        = var.internal_api_key
    GOOGLE_CLIENT_ID        = var.google_client_id
    GOOGLE_CLIENT_SECRET    = var.google_client_secret
    KAKAO_CLIENT_ID         = var.kakao_client_id
    KAKAO_CLIENT_SECRET     = var.kakao_client_secret
    NAVER_CLIENT_ID         = var.naver_client_id
    NAVER_CLIENT_SECRET     = var.naver_client_secret
    ENCRYPTION_AES_KEY      = var.encryption_aes_key
    ENCRYPTION_HMAC_KEY     = var.encryption_hmac_key
    TOSS_CLIENT_KEY         = var.toss_client_key
    TOSS_SECRET_KEY         = var.toss_secret_key
    SMTP_USER               = var.smtp_user
    SMTP_PASSWORD           = var.smtp_password
  }

  depends_on = [kubernetes_namespace.prod]
}

# ============================================================
# K8s ConfigMap: app-config
#  Spring Boot 앱 서비스들이 사용하는 공통 설정
#  RDS endpoint는 Terraform이 aws_db_instance에서 자동으로 주입
# ============================================================
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  data = {
    # ── 데이터베이스 (RDS) ────────────────────────────────
    DB_HOST     = aws_db_instance.main.address
    DB_PORT     = "5432"
    DB_USERNAME = var.db_username
    DB_NAME     = var.db_name

    # 서비스별 DB URL (스키마 분리)
    USER_DB_URL     = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=auth"
    PRODUCT_DB_URL  = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=products"
    BOOKING_DB_URL  = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=booking"
    PAYMENTS_DB_URL = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=payments"
    REVIEWS_DB_URL  = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=reviews"
    SKUS_DB_URL     = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=skus"
    LOCATION_DB_URL = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=location"
    MEDIA_DB_URL    = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=media"
    ORDERS_DB_URL   = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}?currentSchema=booking"

    # Read Replica: RDS 단일 인스턴스이므로 비활성화
    DB_REPLICA_ENABLED = "false"
    DB_REPLICA_URL     = "jdbc:postgresql://${aws_db_instance.main.address}:5432/${var.db_name}"

    # ── Keycloak ──────────────────────────────────────────
    KEYCLOAK_INTERNAL_URL = "http://keycloak:8080"
    KEYCLOAK_EXTERNAL_URL = "http://keycloak:8080"
    KEYCLOAK_REALM        = "Ticket-Service-Realm"
    KEYCLOAK_CLIENT_ID    = "bff-client"

    # ── Redis ─────────────────────────────────────────────
    REDIS_HOST             = "redis"
    REDIS_PORT             = "6379"
    REDIS_SSL_ENABLED      = "false"
    REDIS_BUSINESS_HOST    = "redis-business"
    REDIS_BUSINESS_PORT    = "6379"

    # ── Kafka ─────────────────────────────────────────────
    KAFKA_BOOTSTRAP_SERVERS          = "kafka:9092"
    KAFKA_BUSINESS_BOOTSTRAP_SERVERS = "kafka-business:9092"

    # ── Elasticsearch ─────────────────────────────────────
    ELASTICSEARCH_HOST = "elasticsearch"
    ELASTICSEARCH_PORT = "9200"

    # ── SMTP (MailHog in-cluster) ─────────────────────────
    SMTP_HOST = "mailhog"
    SMTP_PORT = "1025"

    # ── AWS S3 ────────────────────────────────────────────
    S3_REGION   = var.aws_region
    S3_ENDPOINT = "https://s3.${var.aws_region}.amazonaws.com"
    S3_BUCKET   = "${var.cluster_name}-bucket"

    # ── 서비스 간 URL ────────────────────────────────────
    USER_WRITE_SERVICE_URL          = "http://user-write-service"
    USER_WRITE_SERVICE_GRPC_HOST    = "user-write-service"
    USER_WRITE_SERVICE_GRPC_PORT    = "9188"
    SKU_FLIGHTS_WRITE_SERVICE_URL   = "http://sku-flights-write-service"
    SKU_FLIGHTS_READ_SERVICE_URL    = "http://sku-flights-read-service"
    ORDERS_WRITE_SERVICE_URL        = "http://orders-write-service"
    ORDERS_READ_SERVICE_URL         = "http://orders-read-service"
    PAYMENTS_WRITE_SERVICE_URL      = "http://payments-write-service"
    PAYMENTS_READ_SERVICE_URL       = "http://payments-read-service"
    ORDER_ITEMS_WRITE_SERVICE_URL   = "http://order-items-write-service"
    ORDER_ITEMS_READ_SERVICE_URL    = "http://order-items-read-service"

    # ── 앱 설정 ──────────────────────────────────────────
    APP_FRONTEND_URL         = "http://localhost:5173"
    SOCIAL_LOGIN_SUCCESS_URL = "http://localhost:5173/login/success"
    SOCIAL_LOGIN_ERROR_URL   = "http://localhost:5173/login/error"
    SOCIAL_CALLBACK_BASE_URL = "http://localhost:8080"
  }

  depends_on = [kubernetes_namespace.prod, aws_db_instance.main]
}
