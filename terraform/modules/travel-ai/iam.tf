data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "travel_ai_lambda" {
  name               = "travel-ai-lambda-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
  }
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.travel_ai_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.travel_ai_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    sid    = "BedrockInvokeModels"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      # Titan Embeddings V2
      "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0",
      # Nova Pro
      "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.nova-pro-v1:0",
      # Claude Sonnet 4.5 (inference profile)
      "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-sonnet-4-5*",
      "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-5*",
      "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-sonnet-4-5*",
    ]
  }
}

resource "aws_iam_policy" "bedrock_invoke" {
  name        = "travel-ai-bedrock-invoke-${var.environment}"
  description = "Bedrock InvokeModel 권한 (Titan Embeddings V2, Nova Pro, Claude Sonnet 4.5)"
  policy      = data.aws_iam_policy_document.bedrock_invoke.json

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
  }
}

resource "aws_iam_role_policy_attachment" "bedrock_invoke" {
  role       = aws_iam_role.travel_ai_lambda.name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

# ============================================================
# Guardrail 권한 — ApplyGuardrail, GetGuardrail
# ============================================================
data "aws_iam_policy_document" "bedrock_guardrail" {
  statement {
    sid    = "BedrockGuardrail"
    effect = "Allow"
    actions = [
      "bedrock:ApplyGuardrail",
      "bedrock:GetGuardrail",
    ]
    resources = [
      aws_bedrock_guardrail.travel_ai.guardrail_arn,
    ]
  }
}

resource "aws_iam_policy" "bedrock_guardrail" {
  name        = "travel-ai-bedrock-guardrail-${var.environment}"
  description = "Bedrock Guardrail 적용 권한"
  policy      = data.aws_iam_policy_document.bedrock_guardrail.json

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
  }
}

resource "aws_iam_role_policy_attachment" "bedrock_guardrail" {
  role       = aws_iam_role.travel_ai_lambda.name
  policy_arn = aws_iam_policy.bedrock_guardrail.arn
}
