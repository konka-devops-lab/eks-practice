locals {
  name = "${var.environment}-${var.project}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
    tags = merge(
      {
        Name                                                      = local.name
        "kubernetes.io/cluster/${var.environment}-${var.project}" = "owned"
        "karpenter.sh/discovery"                                  = "${var.environment}-${var.project}"
      },
      var.common_tags

    )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )
}

###############################################################################
# Subnets
###############################################################################
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    {
      Name                                                      = "${local.name}-public-subnet-${split("-", var.azs[count.index])[2]}"
      "kubernetes.io/cluster/${var.environment}-${var.project}" = "owned"
      "kubernetes.io/role/elb"                                  = 1
      # "karpenter.sh/discovery"                                  = "${var.environment}-${var.project}"
    },
    var.common_tags
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]
  tags = merge(
    {
      Name                                                      = "${local.name}-private-subnet-${split("-", var.azs[count.index])[2]}"
      "kubernetes.io/cluster/${var.environment}-${var.project}" = "owned"
      "kubernetes.io/role/internal-elb"                         = 1
      "karpenter.sh/discovery"                                  = "${var.environment}-${var.project}"
    },
    var.common_tags
  )
}

resource "aws_subnet" "db" {
  count             = length(var.db_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]
  tags = merge(
    {
      Name                                                      = "${local.name}-db-subnet-${split("-", var.azs[count.index])[2]}"
      "kubernetes.io/cluster/${var.environment}-${var.project}" = "owned"
    },
    var.common_tags
  )
}

resource "aws_db_subnet_group" "default" {
  name       = local.name
  subnet_ids = [for s in aws_subnet.db : s.id]
  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )
}

################################################################################
# Route Tables
################################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name}-public"
    },
    var.common_tags
  )
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name}-private"
    },
    var.common_tags
  )
}
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name}-db"
    },
    var.common_tags
  )
}

##################################################################################
# Route Table Associations
##################################################################################
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

###################################################################################
# EIP, NAT Gateway
###################################################################################
resource "aws_eip" "eks" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"
}
resource "aws_nat_gateway" "example" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.eks[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    {
      Name = "${local.name}-NAT"
    },
    var.common_tags
  )
  depends_on = [aws_internet_gateway.gw]
}
##################################################################################
# Routes
##################################################################################
resource "aws_route" "public_all_traffic" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}
resource "aws_route" "private_nat_internet" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.example[0].id
}
resource "aws_route" "db_nat_internet" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.db.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.example[0].id
}