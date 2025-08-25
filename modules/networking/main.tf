resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public "management" subnets (map_public_ip_on_launch = true)
resource "aws_subnet" "mgmt" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.mgmt_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-mgmt-${count.index}"
    Tier = "management"
  }
}

# Private "application" subnets
resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-app-${count.index}"
    Tier = "application"
  }
}

# Private "backend" subnets
resource "aws_subnet" "backend" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.be_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-backend-${count.index}"
    Tier = "backend"
  }
}

# Public route table (0.0.0.0/0 via IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

# Associate public RT to both mgmt subnets
resource "aws_route_table_association" "public_mgmt" {
  count          = 2
  subnet_id      = aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT per AZ (recommended for HA)
resource "aws_eip" "nat" {
  count  = var.enable_nat_per_az ? 2 : 1
  domain = "vpc"

  tags = { Name = "${var.project_name}-nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_per_az ? 2 : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.mgmt[var.enable_nat_per_az ? count.index : 0].id

  tags = { Name = "${var.project_name}-nat-${count.index}" }

  depends_on = [aws_internet_gateway.this]
}

# Private route tables, one per AZ, default route via NAT in same AZ
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.enable_nat_per_az ? count.index : 0].id
  }

  tags = { Name = "${var.project_name}-private-rt-${count.index}" }
}

# Associate app subnets to their AZ's private RT
resource "aws_route_table_association" "app_private" {
  count          = 2
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Associate backend subnets to their AZ's private RT
resource "aws_route_table_association" "backend_private" {
  count          = 2
  subnet_id      = aws_subnet.backend[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
