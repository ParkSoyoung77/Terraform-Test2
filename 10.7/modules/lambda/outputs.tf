output "s3_function_name" {
  value = aws_lambda_function.std17_s3_bucket_function.function_name
}

output "s3_function_invoke_arn" {
  value = aws_lambda_function.std17_s3_bucket_function.invoke_arn
}