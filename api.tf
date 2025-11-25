# API Gateway v2 (HTTP API) to trigger Lambda for presigned URL generation
resource "aws_apigatewayv2_api" "main_api" {
  name          = "dataprocess-api"
  protocol_type = "HTTP"
  
  # CORS (Cross-Origin Resource Sharing) configuration
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["Content-Type"]
  }
}

# Default stage for the API
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main_api.id
  name        = "$default"
  auto_deploy = true
}

# Integration (link API <-> Lambda)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.main_api.id
  integration_type = "AWS_PROXY"
  
  integration_uri    = aws_lambda_function.get_presigned_url.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Route: mapping between HTTP method/path and the integration
# Call the Lambda on GET /upload for presigned URL
resource "aws_apigatewayv2_route" "get_upload_url" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "GET /upload"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_presigned_url.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main_api.execution_arn}/*/*"
}