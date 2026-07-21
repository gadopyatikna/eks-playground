data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)

  public_subnet_cidrs      = slice(["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"], 0, var.availability_zone_count)
  private_app_subnet_cidrs = slice(["10.20.30.0/24", "10.20.31.0/24", "10.20.32.0/24"], 0, var.availability_zone_count)
  nat_gateway_count        = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.availability_zone_count) : 0

  eks_cluster_name = "${var.name}-${var.environment}-eks"

  common_tags = merge(
    {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  count = var.availability_zone_count

  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = local.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                                              = "${var.name}-${var.environment}-public-${local.azs[count.index]}"
    Tier                                              = "public"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                          = "1"
  })
}

resource "aws_subnet" "private_app" {
  count = var.availability_zone_count

  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = local.private_app_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name                                              = "${var.name}-${var.environment}-private-app-${local.azs[count.index]}"
    Tier                                              = "private-app"
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_app" {
  count = var.availability_zone_count

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-private-app-rt-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "private_app" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

resource "aws_security_group" "client_web_alb" {
  name        = "${var.name}-${var.environment}-client-web-alb"
  description = "Internet-facing ALB for client-facing webapp."
  vpc_id      = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-client-web-alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "client_web_alb_http" {
  security_group_id = aws_security_group.client_web_alb.id
  description       = "HTTP from internet; redirect to HTTPS at the ALB."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "client_web_alb_https" {
  security_group_id = aws_security_group.client_web_alb.id
  description       = "HTTPS from internet."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "client_web_alb_to_eks_pods" {
  for_each = toset(local.private_app_subnet_cidrs)

  security_group_id = aws_security_group.client_web_alb.id
  description       = "Forward traffic to EKS Pods in private app subnets."
  cidr_ipv4         = each.value
  from_port         = var.client_webapp_port
  to_port           = var.client_webapp_port
  ip_protocol       = "tcp"
}
