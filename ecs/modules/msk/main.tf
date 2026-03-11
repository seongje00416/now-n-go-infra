# ============================================================
# MSK Serverless 모듈
# - auth 클러스터: 인증 도메인 이벤트 처리
# - business 클러스터: 예약/결제 등 비즈니스 도메인 이벤트 처리
# - IAM 인증 방식 사용
# ============================================================

# ------------------------------
# auth MSK Serverless 클러스터
# - user-registered, user-domain-events 등 인증 관련 토픽
# ------------------------------
resource "aws_msk_serverless_cluster" "auth" {
  cluster_name = "${var.project_name}-${var.environment}-msk-auth"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-msk-auth"
    Project     = var.project_name
    Environment = var.environment
    Role        = "auth"
  }
}

# ------------------------------
# business MSK Serverless 클러스터
# - booking-events, payment-events 등 비즈니스 도메인 토픽
# ------------------------------
resource "aws_msk_serverless_cluster" "business" {
  cluster_name = "${var.project_name}-${var.environment}-msk-business"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-msk-business"
    Project     = var.project_name
    Environment = var.environment
    Role        = "business"
  }
}
