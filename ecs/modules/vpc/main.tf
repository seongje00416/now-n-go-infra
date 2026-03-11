# ============================================================
# 사용 가능한 AZ 목록 조회 (data source)
#  var.azs가 비어있을 경우 자동으로 AZ를 조회한다
# ============================================================
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  # var.azs가 지정되면 그것을 사용, 아니면 data source에서 앞 2개를 사용
  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, 2)
}

# ============================================================
# VPC 생성
# ============================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true   # ECS Fargate 태스크가 DNS 이름을 가질 수 있도록 설정
  enable_dns_support   = true

  tags = {
    Name       = "${local.name_prefix}-vpc"
    managed-by = "terraform"
  }
}

# ============================================================
# 퍼블릭 서브넷 (ALB, NAT Gateway용)
#  인터넷에서 직접 접근 가능한 서브넷
#  ALB와 NAT GW가 여기에 생성됨
# ============================================================
resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.1.0.0/24", "10.1.1.0/24"][count.index]
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true   # 퍼블릭 서브넷이므로 자동으로 공인 IP 할당

  tags = {
    Name       = "${local.name_prefix}-public-${count.index + 1}"
    managed-by = "terraform"
  }
}

# ============================================================
# 프라이빗 앱 서브넷 (ECS Fargate 태스크용)
#  인터넷에서 직접 접근 불가한 서브넷
#  ECS Fargate 태스크가 여기에 배치됨
#  /20 블록으로 크게 할당 — Fargate ENI 대량 할당에 대비
# ============================================================
resource "aws_subnet" "private_app" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.1.10.0/20", "10.1.32.0/20"][count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name       = "${local.name_prefix}-private-app-${count.index + 1}"
    managed-by = "terraform"
  }
}

# ============================================================
# 프라이빗 데이터 서브넷 (RDS, ElastiCache, MSK, OpenSearch용)
#  데이터 계층 서비스만 위치하는 격리된 서브넷
# ============================================================
resource "aws_subnet" "private_data" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.1.100.0/24", "10.1.101.0/24"][count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name       = "${local.name_prefix}-private-data-${count.index + 1}"
    managed-by = "terraform"
  }
}

# ============================================================
# 인터넷 게이트웨이
#  퍼블릭 서브넷이 인터넷과 통신하기 위해 필요
# ============================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name       = "${local.name_prefix}-igw"
    managed-by = "terraform"
  }
}

# ============================================================
# NAT 게이트웨이
#  프라이빗 서브넷의 ECS 태스크들이 인터넷에 접근할 수 있도록 해주는 게이트웨이
#  (예: ECR 이미지 Pull, AWS API 호출 등)
#  NAT GW는 퍼블릭 서브넷에 위치하고, 고정 IP(EIP)가 필요
#  비용 절감을 위해 NAT GW는 1개만 생성 (단일 AZ 장애 허용)
# ============================================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name       = "${local.name_prefix}-nat-eip"
    managed-by = "terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id   # 첫 번째 퍼블릭 서브넷에 NAT GW 배치

  tags = {
    Name       = "${local.name_prefix}-nat-gw"
    managed-by = "terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================================
# 라우팅 테이블
#  서브넷이 어디로 트래픽을 보낼지 설정
# ============================================================

# 퍼블릭 라우팅 테이블: 인터넷 트래픽 -> 인터넷 게이트웨이
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name       = "${local.name_prefix}-public-rt"
    managed-by = "terraform"
  }
}

# 프라이빗 라우팅 테이블: 인터넷 트래픽 -> NAT 게이트웨이
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name       = "${local.name_prefix}-private-rt"
    managed-by = "terraform"
  }
}

# 라우팅 테이블 <-> 서브넷 연결
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data" {
  count          = 2
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# VPC 엔드포인트 — S3 Gateway
#  프라이빗 서브넷에서 S3로의 트래픽이 인터넷을 거치지 않도록 설정
#  NAT GW 비용 절감 + 보안 강화
# ============================================================
data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id,
  ]

  tags = {
    Name       = "${local.name_prefix}-vpce-s3"
    managed-by = "terraform"
  }
}

# ============================================================
# VPC 엔드포인트 — DynamoDB Gateway
#  프라이빗 서브넷에서 DynamoDB로의 트래픽이 인터넷을 거치지 않도록 설정
# ============================================================
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id,
  ]

  tags = {
    Name       = "${local.name_prefix}-vpce-dynamodb"
    managed-by = "terraform"
  }
}
