# =============================================================================
# main.tf — Root orchestrator for Now & Go ECS infrastructure
# =============================================================================

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

# =============================================================================
# Cloud Map — private DNS namespace for ECS service discovery
# =============================================================================

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "nowandgo.local"
  description = "Private DNS namespace for Now & Go ECS service discovery"
  vpc         = module.vpc.vpc_id
}

# =============================================================================
# Module: VPC
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
}

# =============================================================================
# Module: Security Groups
# =============================================================================

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# =============================================================================
# Module: IAM
# =============================================================================

module "iam" {
  source = "./modules/iam"

  project_name          = var.project_name
  environment           = var.environment
  s3_bucket_arns        = [module.s3.user_profiles_bucket_arn, module.s3.media_bucket_arn]
  dynamodb_table_arn    = module.dynamodb.table_arn
  opensearch_domain_arn = module.opensearch.domain_arn
}

# =============================================================================
# Module: ECR
# =============================================================================

module "ecr" {
  source = "./modules/ecr"

  project_name  = var.project_name
  service_names = local.ecr_services
}

# =============================================================================
# Module: S3
# =============================================================================

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# =============================================================================
# Module: DynamoDB
# =============================================================================

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
}

# =============================================================================
# Module: RDS (PostgreSQL — primary + read replica)
# =============================================================================

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_data_subnet_ids
  security_group_ids = [module.security_groups.rds_sg_id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

# =============================================================================
# Module: ElastiCache (Redis — auth + business clusters)
# =============================================================================

module "elasticache" {
  source = "./modules/elasticache"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_data_subnet_ids
  security_group_ids = [module.security_groups.redis_sg_id]
  auth_password      = var.redis_auth_password
  business_password  = var.redis_business_password
}

# =============================================================================
# Module: MSK Serverless (Kafka — auth + business clusters)
# =============================================================================

module "msk" {
  source = "./modules/msk"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_data_subnet_ids
  security_group_ids = [module.security_groups.msk_sg_id]
}

# =============================================================================
# Module: OpenSearch
# =============================================================================

module "opensearch" {
  source = "./modules/opensearch"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_data_subnet_ids
  security_group_ids = [module.security_groups.opensearch_sg_id]
}

# =============================================================================
# Module: Secrets Manager + SSM Parameter Store
# (depends on RDS — needs endpoints after creation)
# =============================================================================

module "secrets" {
  source = "./modules/secrets"

  project_name            = var.project_name
  environment             = var.environment
  db_credentials          = { username = var.db_username, password = var.db_password }
  redis_auth_password     = var.redis_auth_password
  redis_business_password = var.redis_business_password
  encryption_aes_key      = var.encryption_aes_key
  encryption_hmac_key     = var.encryption_hmac_key
  internal_api_key        = var.internal_api_key
  keycloak_admin_password = var.keycloak_admin_password
  rds_primary_endpoint    = module.rds.primary_endpoint
  rds_replica_endpoint    = module.rds.replica_endpoint
  db_name                 = var.db_name
}

# =============================================================================
# Module: ECS Cluster
# =============================================================================

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  project_name = var.project_name
  environment  = var.environment
}

# =============================================================================
# Module: ALB (Application Load Balancer)
# =============================================================================

module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]
}

# =============================================================================
# Module: Monitoring (CloudWatch log groups + alarms + dashboard)
# =============================================================================

module "monitoring" {
  source = "./modules/monitoring"

  project_name       = var.project_name
  environment        = var.environment
  service_names      = keys(local.services)
  log_retention_days = var.log_retention_days
  alb_arn            = module.alb.alb_arn
  cluster_name       = module.ecs_cluster.cluster_name
}

# =============================================================================
# Module: ECS Services (one per entry in local.services)
# =============================================================================

module "ecs_service" {
  source   = "./modules/ecs-service"
  for_each = local.services

  project_name = var.project_name
  environment  = var.environment

  # Service identity
  service_name = each.key
  cluster_id   = module.ecs_cluster.cluster_id

  # Container image: use explicit image if provided (e.g. keycloak official),
  # otherwise fall back to the ECR repo built from the Dockerfile.
  container_image = try(
    each.value.container_image,
    "${module.ecr.repository_urls[each.key]}:latest"
  )

  container_port = each.value.container_port
  grpc_port      = try(each.value.grpc_port, null)
  cpu            = each.value.cpu
  memory         = each.value.memory
  desired_count  = each.value.desired_count

  # Network
  subnet_ids         = module.vpc.private_app_subnet_ids
  security_group_ids = [module.security_groups.ecs_service_sg_id]

  # IAM
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arns[each.value.task_role]

  # Service discovery
  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.main.id

  # Environment variables & secrets
  environment_variables = each.value.environment
  secrets               = {}

  # Health check
  health_check_path = each.value.health_check_path

  # ALB integration (gateway-service only)
  enable_alb       = each.value.enable_alb
  target_group_arn = each.value.enable_alb ? module.alb.gateway_target_group_arn : ""

  # Logging
  log_group_name = module.monitoring.log_group_names[each.key]
  aws_region     = var.aws_region
}
