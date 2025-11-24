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
data "archive_file" "zip_enrichissement" {
  type        = "zip"
  source_file = "src/enrichissement.py" 
  output_path = "enrichissement.zip"
}

# Create the lambda function Enrichment
resource "aws_lambda_function" "Enrichment" {
    function_name = "EnrichmentFunction"

    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key    = aws_s3_object.lambda_enrichment.key

    runtime = "python3.11"
    handler = "enrichment.lambda_handler"

    filename = data.archive_file.zip_enrichment.output_path
    source_code_hash = data.archive_file.lambda_enrichment.output_base64sha256

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