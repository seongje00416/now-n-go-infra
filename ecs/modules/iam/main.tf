locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # ECS 태스크 신뢰 정책 — 모든 역할에 공통 적용
  ecs_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# ============================================================
# ECS 태스크 실행 역할 (Task Execution Role)
#  모든 서비스가 공유하는 실행 역할
#  ECR 이미지 Pull, CloudWatch Logs 기록,
#  Secrets Manager / SSM Parameter Store 조회에 사용
# ============================================================
resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-ecs-task-execution-role"
  assume_role_policy = local.ecs_assume_role_policy

  tags = {
    Name       = "${local.name_prefix}-ecs-task-execution-role"
    managed-by = "terraform"
  }
}

# AWS 관리형 정책: ECS 태스크 실행 기본 권한 (ECR, CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 인라인 정책: Secrets Manager, SSM, ECR, Logs 추가 권한
resource "aws_iam_role_policy" "task_execution_inline" {
  name = "${local.name_prefix}-task-execution-inline"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Secrets Manager에서 비밀 값 조회 (DB 비밀번호, API 키 등)
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = ["arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"]
      },
      {
        # SSM Parameter Store 파라미터 조회
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
        ]
        Resource = ["arn:aws:ssm:*:*:parameter/${var.project_name}/*"]
      },
      {
        # ECR 전체 권한 (이미지 Pull을 위한 추가 권한)
        Sid      = "ECRAccess"
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = ["*"]
      },
      {
        # CloudWatch Logs 전체 권한
        Sid      = "CloudWatchLogsAccess"
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = ["*"]
      },
    ]
  })
}

# ============================================================
# 기본 태스크 역할 (default-task-role)
#  추가 권한 없음 — 범용 서비스용
# ============================================================
resource "aws_iam_role" "default_task" {
  name               = "${local.name_prefix}-default-task-role"
  assume_role_policy = local.ecs_assume_role_policy

  tags = {
    Name       = "${local.name_prefix}-default-task-role"
    managed-by = "terraform"
  }
}

# ============================================================
# Auth 태스크 역할 (auth-task-role)
#  유저 프로필 S3 버킷 접근 + SQS 큐 전송 권한
# ============================================================
resource "aws_iam_role" "auth_task" {
  name               = "${local.name_prefix}-auth-task-role"
  assume_role_policy = local.ecs_assume_role_policy

  tags = {
    Name       = "${local.name_prefix}-auth-task-role"
    managed-by = "terraform"
  }
}

resource "aws_iam_role_policy" "auth_task_inline" {
  name = "${local.name_prefix}-auth-task-inline"
  role = aws_iam_role.auth_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # user-profiles S3 버킷 객체 CRUD 권한
        Sid    = "UserProfilesS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = length(var.s3_bucket_arns) > 0 ? [
          for arn in var.s3_bucket_arns : "${arn}/*"
        ] : ["arn:aws:s3:::*nowandgo*/*"]
      },
      {
        # nowandgo SQS 큐 전체 권한
        Sid    = "NowAndGoSQSAccess"
        Effect = "Allow"
        Action = ["sqs:*"]
        Resource = ["arn:aws:sqs:*:*:nowandgo-*"]
      },
    ]
  })
}

# ============================================================
# Booking 태스크 역할 (booking-task-role)
#  주문 DynamoDB 테이블 전체 권한
# ============================================================
resource "aws_iam_role" "booking_task" {
  name               = "${local.name_prefix}-booking-task-role"
  assume_role_policy = local.ecs_assume_role_policy

  tags = {
    Name       = "${local.name_prefix}-booking-task-role"
    managed-by = "terraform"
  }
}

resource "aws_iam_role_policy" "booking_task_inline" {
  name = "${local.name_prefix}-booking-task-inline"
  role = aws_iam_role.booking_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 주문 DynamoDB 테이블 전체 권한
        Sid      = "OrdersDynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = [var.dynamodb_table_arn]
      },
    ]
  })
}

# ============================================================
# Travel AI 태스크 역할 (travel-ai-task-role)
#  Bedrock 모델 추론 + OpenSearch HTTP 접근 권한
#  RAG 기반 여행 추천 서비스에서 사용
# ============================================================
resource "aws_iam_role" "travel_ai_task" {
  name               = "${local.name_prefix}-travel-ai-task-role"
  assume_role_policy = local.ecs_assume_role_policy

  tags = {
    Name       = "${local.name_prefix}-travel-ai-task-role"
    managed-by = "terraform"
  }
}

resource "aws_iam_role_policy" "travel_ai_task_inline" {
  name = "${local.name_prefix}-travel-ai-task-inline"
  role = aws_iam_role.travel_ai_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Bedrock 모델 추론 권한
        #  - Titan Embed V2: 텍스트 임베딩 생성 (RAG 벡터화)
        #  - Amazon Nova Pro: 여행 추천 생성
        #  - Claude Sonnet: 자연어 여행 플래너
        Sid    = "BedrockInvokeModel"
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-text-v2:0",
          "arn:aws:bedrock:*::foundation-model/amazon.nova-pro-v1:0",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
        ]
      },
      {
        # OpenSearch 도메인 HTTP 요청 권한 (하이브리드 검색)
        Sid      = "OpenSearchAccess"
        Effect   = "Allow"
        Action   = ["es:ESHttp*"]
        Resource = [var.opensearch_domain_arn]
      },
    ]
  })
}
