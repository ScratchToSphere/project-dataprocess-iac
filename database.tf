# Random password for the DB master user
resource "random_password" "db_password" {
  length           = 16
  special          = false # Avoid special characters for simplicity with urls
}

# Security Group for Aurora
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "dataprocess-aurora-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Aurora Subnet Group"
  }
}

# Create the Aurora Serverless Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier     = "dataprocess-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned" # Prerequisite for Serverless v2
  engine_version         = "14.6"        # Compatible versiob Serverless v2
  database_name          = "dataprocessdb"
  master_username        = "adminuser"
  master_password        = random_password.db_password.result
  
  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  skip_final_snapshot    = true # Easily destroyable for the lab (PUT FALSE in prod!)

  # Serverless v2 configuration (cost optimization for the lab)
  serverlessv2_scaling_configuration {
    max_capacity = 1.0 # Max 1 ACU (Enough for the labo)
    min_capacity = 0.5 # Min 0.5 ACU (Most affordable)
  }
}


resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless" # Magic !
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}