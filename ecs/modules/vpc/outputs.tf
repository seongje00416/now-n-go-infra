output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록 (ALB, NAT GW용)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "프라이빗 앱 서브넷 ID 목록 (ECS Fargate 태스크용)"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "프라이빗 데이터 서브넷 ID 목록 (RDS, ElastiCache, MSK, OpenSearch용)"
  value       = aws_subnet.private_data[*].id
}

output "nat_gateway_id" {
  description = "NAT 게이트웨이 ID"
  value       = aws_nat_gateway.main.id
}

output "vpc_endpoint_s3_id" {
  description = "S3 Gateway VPC 엔드포인트 ID"
  value       = aws_vpc_endpoint.s3.id
}
