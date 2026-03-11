output "recommend_function_url" {
  description = "travel-ai-recommend Lambda 함수 URL"
  value       = aws_lambda_function_url.recommend.function_url
}

output "recommend_function_arn" {
  description = "travel-ai-recommend Lambda 함수 ARN"
  value       = aws_lambda_function.recommend.arn
}

output "indexer_function_arn" {
  description = "travel-ai-indexer Lambda 함수 ARN"
  value       = aws_lambda_function.indexer.arn
}

output "lambda_security_group_id" {
  description = "travel-ai Lambda 보안 그룹 ID"
  value       = aws_security_group.lambda.id
}

output "guardrail_id" {
  description = "Bedrock Guardrail ID"
  value       = aws_bedrock_guardrail.travel_ai.guardrail_id
}

output "guardrail_version" {
  description = "Bedrock Guardrail 프로덕션 버전 번호"
  value       = aws_bedrock_guardrail_version.travel_ai.version
}
