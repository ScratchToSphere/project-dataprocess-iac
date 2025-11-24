# S3 full access policy attachment (Temporary)
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# IAM Role for Lambda Execution with S3 Access
resource "aws_iam_role" "lambda_exec" {
  name = "dataprocess-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Step Functions IAM Role
resource "aws_iam_role" "step_function_role" {
  name = "dataprocess-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

# Step Functions policy to invoke Lambdas
resource "aws_iam_policy" "sfn_policy" {
  name        = "dataprocess-sfn-policy"
  description = "Permet d'invoquer les Lambdas du projet"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          aws_lambda_function.Enrichment.arn,
          aws_lambda_function.Anonymization.arn,
          aws_lambda_function.Consolidation.arn
        ]
      }
    ]
  })
}

# Step Functions policy attachment
resource "aws_iam_role_policy_attachment" "sfn_policy_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}

# Security Group for Lambda functions, Consolidation in particular
resource "aws_security_group" "lambda_sg" {
  name        = "dataprocess-lambda-sg"
  description = "Security Group for Lambda Consolidation"
  vpc_id      = aws_vpc.main.id

  # Outbound rules to allow all traffic (from Lambda to anywhere) 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dataprocess-lambda-sg"
  }
}

# Security Group for Aurora Cluster
resource "aws_security_group" "aurora_sg" {
  name        = "dataprocess-aurora-sg"
  description = "Security Group for Aurora Cluster"
  vpc_id      = aws_vpc.main.id

  # Inbound rule to allow traffic from Lambda SG on port 5432 (PostgreSQL)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id] # Allow from Lambda SG
  }

  tags = {
    Name = "dataprocess-aurora-sg"
  }
}

# Lambda VPC Access policy attachment
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}