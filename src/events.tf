# Capture S3 Upload Events and Trigger Step Functions State Machine
resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "capture-s3-upload"
  description = "Start Step Functions workflow on S3 upload to input bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail-type = ["Object Created"],
    detail = {
      bucket = {
        name = [aws_s3_bucket.dataprocess-input-thomas.id]
      },
      object = {
        key = [{ suffix = ".json" }] # Only start for .json files
      }
    }
  })
}

# Target: Step Functions State Machine
resource "aws_cloudwatch_event_target" "trigger_sfn" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  target_id = "SendToStepFunctions"
  arn       = aws_sfn_state_machine.sfn_workflow.arn
  
  # IAM Role allowing EventBridge to start Step Functions execution
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# IAM Role for EventBridge to invoke Step Functions
resource "aws_iam_role" "eventbridge_role" {
  name = "dataprocess-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

# Policy to allow EventBridge to start Step Functions execution
resource "aws_iam_role_policy" "eventbridge_invoke_sfn" {
  name = "invoke_step_function"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "states:StartExecution",
      Resource = aws_sfn_state_machine.sfn_workflow.arn
    }]
  })
}