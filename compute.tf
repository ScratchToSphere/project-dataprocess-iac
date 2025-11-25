# Create the S3 bucket for uploading data
resource "aws_s3_bucket" "dataprocess-input-thomas" {
  bucket = "dataprocess-input-thomas"

  tags = {
    Name        = "Upload Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.dataprocess-input-thomas.id
  eventbridge = true
}

# Create the S3 bucket for processed data
resource "aws_s3_bucket" "dataprocess-output-thomas" {
  bucket = "dataprocess-output-thomas"

  tags = {
    Name        = "Processed Data Bucket"
    Environment = "Dev"
  }
}

# Create the code archive for the Lambda function Enrichment
data "archive_file" "zip_enrichment" {
  type        = "zip"
  source_file = "src/enrichment.py" 
  output_path = "enrichment.zip"
}

# Create the code archive for the Lambda function anonymization
data "archive_file" "zip_anonymization" {
  type        = "zip"
  source_file = "src/anonymization.py" 
  output_path = "anonymization.zip"
}

# Create the code archive for the Lambda function consolidation
data "archive_file" "zip_consolidation" {
  type        = "zip"
  source_file = "src/consolidation.py" 
  output_path = "consolidation.zip"
}

# Create the lambda function Enrichment
resource "aws_lambda_function" "Enrichment" {
    function_name = "EnrichmentFunction"

    runtime = "python3.11"
    handler = "enrichment.lambda_handler"

    filename = data.archive_file.zip_enrichment.output_path
    source_code_hash = data.archive_file.zip_enrichment.output_base64sha256

    role = aws_iam_role.lambda_exec.arn
}

# Create the lambda function anonymization
resource "aws_lambda_function" "Anonymization" {
    function_name = "AnonymizationFunction"

    runtime = "python3.11"
    handler = "anonymization.lambda_handler"

    filename = data.archive_file.zip_anonymization.output_path
    source_code_hash = data.archive_file.zip_anonymization.output_base64sha256

    role = aws_iam_role.lambda_exec.arn

    # Lambda in VPC
    vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# Create the lambda function consolidation
resource "aws_lambda_function" "Consolidation" {
    function_name = "ConsolidationFunction"

    runtime = "python3.11"
    handler = "consolidation.lambda_handler"

    filename = data.archive_file.zip_consolidation.output_path
    source_code_hash = data.archive_file.zip_consolidation.output_base64sha256

    role = aws_iam_role.lambda_exec.arn

    vpc_config {
    # Lambda in VPC
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    
    # Attach the Lambda SG to allow DB access
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  
  # Database connection parameters as environment variables
  environment {
    variables = {
      DB_HOST     = aws_db_instance.postgres_instance.address
      DB_NAME     = "dataprocessdb"
      DB_USER     = "adminuser"
      # NB : in production we would use AWS Secrets Manager or SSM Parameter Store.
      # For the lab, we accept the risk or we use the random password directly.
      DB_PASSWORD = random_password.db_password.result 
    }
  }
}

# Logs policy attachment
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "sfn_workflow" {
  name     = "DataProcess-Workflow"
  role_arn = aws_iam_role.step_function_role.arn

  definition = templatefile("workflow.asl.json", {
    enrichment_arn    = aws_lambda_function.Enrichment.arn
    anonymization_arn = aws_lambda_function.Anonymization.arn
    consolidation_arn = aws_lambda_function.Consolidation.arn
  })
}

# --- LAMBDA PRESIGNED URL (FRONT DOOR) ---

# Create the code archive for the Lambda function to get presigned URL
data "archive_file" "zip_presigned" {
  type        = "zip"
  source_file = "src/get_presigned_url.py"
  output_path = "presigned.zip"
}

# Create the lambda function to get presigned URL
resource "aws_lambda_function" "get_presigned_url" {
  function_name = "GetPresignedUrlFunction"

  runtime = "python3.11"
  handler = "get_presigned_url.lambda_handler"

  filename         = data.archive_file.zip_presigned.output_path
  source_code_hash = data.archive_file.zip_presigned.output_base64sha256

  role = aws_iam_role.lambda_exec.arn # Reusing the same execution role

  # Bucket name as environment variable
  environment {
    variables = {
      INPUT_BUCKET_NAME = aws_s3_bucket.dataprocess-input-thomas.bucket
    }
  }
}