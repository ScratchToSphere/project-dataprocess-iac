# API Gateway Endpoint Output (public URL)
output "api_endpoint" {
  description = "API Gateway public URL"
  value       = aws_apigatewayv2_api.main_api.api_endpoint
}