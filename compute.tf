# Create the S3 bucket for uploading data
resource "aws_s3_bucket" "dataprocess-input-thomas" {
  bucket = "dataprocess-input-thomas"

  tags = {
    Name        = "Upload Bucket"
    Environment = "Dev"
  }
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
  output_path = "enrichissement.zip"
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
}

# Create the lambda function consolidation
resource "aws_lambda_function" "Consolidation" {
    function_name = "ConsolidationFunction"

    runtime = "python3.11"
    handler = "consolidation.lambda_handler"

    filename = data.archive_file.zip_consolidation.output_path
    source_code_hash = data.archive_file.zip_consolidation.output_base64sha256

    role = aws_iam_role.lambda_exec.arn
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

# Logs policy attachment
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 full access policy attachment (Temporary)
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}