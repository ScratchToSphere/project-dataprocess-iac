# Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "dataprocess-vpc"
    Project = "DataProcess"
  }
}

# Private subnets
# 2 subnets for multi-AZ redundancy
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "dataprocess-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name = "dataprocess-private-b"
  }
}

# Private route table
# Default route table for private subnets, no Internet access
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dataprocess-private-rt"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Security bonus: VPC Endpoint for S3
# Allows lambdas in private subnets to access S3 without going through the Internet
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-west-3.s3"
  vpc_endpoint_type = "Gateway"
  
  # On l'ajoute à la table de routage privée
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "dataprocess-s3-endpoint"
  }
}