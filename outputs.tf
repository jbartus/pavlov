output "pavlov-function-url" {
  value = aws_lambda_function_url.pavlov-function-url.function_url
}

output "env-vars" {
  value     = aws_lambda_function.pavlov-function.environment
  sensitive = true
}
