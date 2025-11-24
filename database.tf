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

# Create the PostgreSQL RDS instance
resource "aws_db_instance" "postgres_instance" {
  identifier             = "dataprocess-db"
  
  # Engine & Version
  engine                 = "postgres"
  engine_version         = "16.10" 
  instance_class         = "db.t3.micro" # Free Tier Eligible
  
  # Storage (required)
  allocated_storage      = 20    # 20 GB (free tier eligible)
  storage_type           = "gp2"
  
  # Login & DB Name
  db_name                = "dataprocessdb"
  username               = "adminuser"
  password               = random_password.db_password.result
  
  # Réseau & Sécurité
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  
  # Lab specific settings
  publicly_accessible    = false # Security: not publicly accessible
  skip_final_snapshot    = true  # Destroy without snapshot for lab purposes
  multi_az               = false # False due to Free Tier limitations (Multi-AZ in prod !)

  tags = {
    Name = "DataProcess-PostgreSQL"
  }
}