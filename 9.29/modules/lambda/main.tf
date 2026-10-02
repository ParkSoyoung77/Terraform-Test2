locals {
  function_name = "std17-lambda-function"
}

# ==================================================================
# Lambda 배포 패키지 빌드 (pymysql은 기본 런타임에 없으므로 함께 패키징)
# ==================================================================

resource "null_resource" "install_lambda_deps" {
  triggers = {
    requirements_hash = filemd5("${path.module}/lambda/requirements.txt")
    source_hash       = filemd5("${path.module}/lambda/lambda_function.py")
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/lambda/requirements.txt -t ${path.module}/lambda --upgrade --no-cache-dir --break-system-packages"
  }
}

data "archive_file" "std17_lambda_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/lambda_function.zip"
  excludes    = ["requirements.txt"]

  depends_on = [null_resource.install_lambda_deps]
}

# ==================================================================
# IAM 역할 / 권한
# ==================================================================

resource "aws_iam_role" "std17_lambda_role" {
  name = "std17-lambda-db-check-role"

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

  tags = { Name = "std17-lambda-db-check-role" }
}

resource "aws_iam_role_policy_attachment" "std17_lambda_vpc_access" {
  role       = aws_iam_role.std17_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "std17_lambda_secrets_access" {
  name = "std17-lambda-secrets-access"
  role = aws_iam_role.std17_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Statement1"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# ==================================================================
# Lambda 함수
# ==================================================================

resource "aws_cloudwatch_log_group" "std17_lambda_function" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "std17_lambda_function" {
  function_name = local.function_name
  role          = aws_iam_role.std17_lambda_role.arn

  filename         = data.archive_file.std17_lambda_function_zip.output_path
  source_code_hash = data.archive_file.std17_lambda_function_zip.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.14"
  timeout = 10

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      DB_SECRET_NAME = var.db_secret_arn
      DB_HOST        = var.db_host
      DB_NAME        = var.db_name
      DB_PORT        = "3306"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.std17_lambda_vpc_access,
    aws_iam_role_policy.std17_lambda_secrets_access,
    aws_cloudwatch_log_group.std17_lambda_function,
  ]

  tags = { Name = local.function_name }
}