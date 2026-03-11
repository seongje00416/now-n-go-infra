# =============================================================================
# outputs.tf — Root-level outputs for Now & Go ECS infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "ALB DNS name (use as Route 53 Alias target or for direct access)"
  value       = module.alb.alb_dns_name
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------

output "rds_primary_endpoint" {
  description = "RDS primary instance endpoint (host:port)"
  value       = module.rds.primary_endpoint
}

output "rds_replica_endpoint" {
  description = "RDS read replica endpoint (host:port)"
  value       = module.rds.replica_endpoint
}

# -----------------------------------------------------------------------------
# ElastiCache (Redis)
# -----------------------------------------------------------------------------

output "redis_auth_endpoint" {
  description = "Auth Redis primary endpoint host"
  value       = module.elasticache.auth_endpoint
}

output "redis_business_endpoint" {
  description = "Business Redis primary endpoint host"
  value       = module.elasticache.business_endpoint
}

# -----------------------------------------------------------------------------
# MSK (Kafka)
# -----------------------------------------------------------------------------

output "msk_auth_bootstrap_servers" {
  description = "Auth MSK Serverless bootstrap servers (SASL/IAM)"
  value       = module.msk.auth_bootstrap_servers
}

output "msk_business_bootstrap_servers" {
  description = "Business MSK Serverless bootstrap servers (SASL/IAM)"
  value       = module.msk.business_bootstrap_servers
}

# -----------------------------------------------------------------------------
# OpenSearch
# -----------------------------------------------------------------------------

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint URL"
  value       = module.opensearch.endpoint
}

# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------

output "ecr_repository_urls" {
  description = "Map of service name -> ECR repository URL"
  value       = module.ecr.repository_urls
}

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

# -----------------------------------------------------------------------------
# Service Discovery
# -----------------------------------------------------------------------------

output "service_discovery_namespace" {
  description = "Cloud Map private DNS namespace (nowandgo.local)"
  value       = aws_service_discovery_private_dns_namespace.main.name
}
