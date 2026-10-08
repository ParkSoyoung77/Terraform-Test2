locals {
  function_name = "std17-lambda-function"

  # lambda_function.py 위치 (파일 위치가 다르면 이 경로만 수정)
  source_file   = "${path.module}/s3_function/lambda_function.py"
}

# ==================================================================
# 배포 패키지
# ==================================================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local.source_file
  output_path = "${path.module}/build/lambda_function.zip"
}

# ==================================================================
# IAM 역할 / 권한
# ==================================================================

resource "aws_iam_role" "lambda_role" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${local.function_name}-role" }
}

# CloudWatch Logs 기록 권한
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==================================================================
# Lambda 함수
# ==================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler     = "lambda_function.lambda_handler" # 파일명.함수명
  runtime     = "python3.14"
  timeout     = 30
  memory_size = 256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = { Name = local.function_name }
}