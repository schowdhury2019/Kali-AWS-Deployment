# ------------------ VPC

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_vpc" "sandbox_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "sandbox-vpc-1"
  }
}

# ------------------ Subnets
resource "aws_subnet" "private_subnet" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "public_subnet" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "public-subnet-1"
  }
}

# ------------------ Route Tables (Public)

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.sandbox_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sandbox_vpc_igw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    "Name" = "public-rt-1"
  }

  depends_on = [
    aws_internet_gateway.sandbox_vpc_igw
  ]
}

resource "aws_main_route_table_association" "public_main_rt_association" {
  vpc_id         = aws_vpc.sandbox_vpc.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------ Route Tables (Private)

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.sandbox_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sandbox_vpc_ng.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    "Name" = "private-rt-1"
  }

  depends_on = [
    aws_nat_gateway.sandbox_vpc_ng
  ]
}

resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ------------------ Internet & NAT Gatways

resource "aws_internet_gateway" "sandbox_vpc_igw" {
  vpc_id = aws_vpc.sandbox_vpc.id
  tags = {
    Name = "sandbox-vpc-igw"
  }
}

resource "aws_eip" "nat_ip" {
  vpc = true
  tags = {
    Name = "sandbox-nat-eip"
  }
}

resource "aws_nat_gateway" "sandbox_vpc_ng" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_ip.id
  subnet_id         = aws_subnet.public_subnet.id

  depends_on = [aws_internet_gateway.sandbox_vpc_igw]
}