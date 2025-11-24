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