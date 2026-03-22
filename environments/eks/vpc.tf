# ============================================================
# VPC 생성
# ============================================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true   # EKS 노드가 DNS 이름을 가질 수 있도록 설정
  enable_dns_support   = true

  tags = {
    Name       = "${var.cluster_name}-vpc"
    managed-by = "terraform"
  }
}

# ============================================================
# 퍼블릭 서브넷 (LoadBalancer용)
#  인터넷에서 직접 접근 가능한 서브넷
#  NLB/ALB가 여기에 생성됨
# ============================================================
resource "aws_subnet" "public" {
  count = 2   # 가용성을 위해 2개의 AZ에 생성

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"    # 10.0.0.0/24, 10.0.1.0/24
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true   # 퍼블릭 서브넷이므로 자동으로 공인 IP 할당

  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"   # AWS LB Controller가 퍼블릭 LB를 이 서브넷에 생성하도록 설정
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ============================================================
# 프라이빗 서브넷 (노드 그룹용)
#  인터넷에서 직접 접근 불가한 서브넷
#  EKS 노드(EC2)가 여기에 생성됨
# ============================================================
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"    # 10.0.10.0/24, 10.0.11.0/24
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"   # 내부 LB용 서브넷임을 표시
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ============================================================
# 인터넷 게이트웨이
#  퍼블릭 서브넷이 인터넷과 통신하기 위해 필요
# ============================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# ============================================================
# NAT 게이트웨이
#  프라이빗 서브넷의 노드들이 인터넷에 접근할 수 있도록 해주는 게이트웨이
#  (예: Docker 이미지 Pull, AWS API 호출 등)
#  NAT GW는 퍼블릭 서브넷에 위치하고, 고정 IP(EIP)가 필요
# ============================================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id   # 퍼블릭 서브넷에 NAT GW 배치

  tags = {
    Name = "${var.cluster_name}-nat-gw"
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
    Name = "${var.cluster_name}-public-rt"
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
    Name = "${var.cluster_name}-private-rt"
  }
}

# 라우팅 테이블 <-> 서브넷 연결
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# 사용 가능한 AZ 목록 조회 (data source)
#  위에서 count.index로 AZ를 선택하기 위해 필요
# ============================================================
data "aws_availability_zones" "available" {
  state = "available"
}
