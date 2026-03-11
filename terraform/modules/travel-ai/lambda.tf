locals {
  common_env_vars = {
    DB_HOST            = var.db_host
    DB_PORT            = tostring(var.db_port)
    DB_NAME            = var.db_name
    DB_USER            = var.db_user
    DB_PASSWORD        = var.db_password
    LLM_MODEL_ID       = var.llm_model_id
    AWS_DEFAULT_REGION = var.aws_region
  }
}

# ──────────────────────────────────────────────
# travel-ai-recommend Lambda
# ──────────────────────────────────────────────
resource "aws_lambda_function" "recommend" {
  function_name = "travel-ai-recommend-${var.environment}"
  role          = aws_iam_role.travel_ai_lambda.arn
  runtime       = "python3.12"
  handler       = "recommend.handler.lambda_handler"
  memory_size   = 1024
  timeout       = 60

  # 초기 배포 시 placeholder zip 사용; 실제 배포는 CI/CD에서 업데이트
  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = local.common_env_vars
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
    Function    = "recommend"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function_url" "recommend" {
  function_name      = aws_lambda_function.recommend.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    max_age           = 86400
  }
}

# ──────────────────────────────────────────────
# travel-ai-indexer Lambda
# ──────────────────────────────────────────────
resource "aws_lambda_function" "indexer" {
  function_name = "travel-ai-indexer-${var.environment}"
  role          = aws_iam_role.travel_ai_lambda.arn
  runtime       = "python3.12"
  handler       = "indexer.handler.lambda_handler"
  memory_size   = 512
  timeout       = 300

  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = local.common_env_vars
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
    Function    = "indexer"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}
