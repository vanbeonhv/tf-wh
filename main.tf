terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.51.1"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  # Configuration options
  region = "ap-southeast-1"
}

# 1 VPC

resource "aws_vpc" "marc-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "marc-vpc"
  }
}

resource "aws_subnet" "marc-private" {
  vpc_id     = aws_vpc.marc-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "marc-private"
  }
}

resource "aws_subnet" "marc-public" {
  vpc_id     = aws_vpc.marc-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "marc-public"
  }
}

# 2 IGW

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.marc-vpc.id

  tags = {
    Name = "marc-igw"
  }
}

# 3: 2 route table (1 public + 1 private)
# Gan IGN vao public RTB
# tat ca cai gi di vao public ma ko biet di dau thi di vao internet gateway
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.marc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rtb"
  }
}

resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.marc-vpc.id

  tags = {
    Name = "private-rtb" 
  }
}



# tat ca cai gi di vao private ma ko biet di dau nua thi di vao NAT
resource "aws_route" "r" {
  route_table_id            = aws_route_table.private-rtb.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat.id
}

# NAT gateway

resource "aws_eip" "nat_gw_eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.marc-public.id

  tags = {
    Name = "marc NAT"
  }

}

# Gan RTB vao Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.marc-public.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.marc-private.id
  route_table_id = aws_route_table.private-rtb.id
}

# Tao EC2 dung subnet public
# Tao EC2 dung subnet private

