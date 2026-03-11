resource "aws_cloudwatch_event_rule" "indexer_daily" {
  name                = "travel-ai-indexer-daily-${var.environment}"
  description         = "매일 오전 3시 KST (18:00 UTC 전날) travel-ai-indexer Lambda 실행"
  schedule_expression = "cron(0 18 * * ? *)"
  state               = "ENABLED"

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
  }
}

resource "aws_cloudwatch_event_target" "indexer_daily" {
  rule      = aws_cloudwatch_event_rule.indexer_daily.name
  target_id = "travel-ai-indexer-target"
  arn       = aws_lambda_function.indexer.arn
  input     = jsonencode({ action = "reindex_all" })
}

resource "aws_lambda_permission" "eventbridge_invoke_indexer" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.indexer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.indexer_daily.arn
}
