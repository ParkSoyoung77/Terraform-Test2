# API Gateway 연결용
output "s3_function_name" {
  value = aws_lambda_function.std17_object_read.function_name
}

output "s3_function_invoke_arn" {
  value = aws_lambda_function.std17_object_read.invoke_arn
}

# 파일 관리 페이지용 Function URL
output "s3_file_function_url" {
  description = "S3 파일 관리(목록/읽기) Lambda 함수 URL"
  value       = aws_lambda_function_url.std17_object_read_url.function_url
}

# 함수 이름 출력용
output "object_read_function_name" {
  value = aws_lambda_function.std17_object_read.function_name
}