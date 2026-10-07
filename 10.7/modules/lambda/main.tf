locals {
  s3_function_name    = "std17-s3-bucket-function"
}

# ==================================================================
# [S3 함수] 배포 패키지 (boto3는 런타임 기본 포함 → 별도 설치 불필요)
# ==================================================================

data "archive_file" "std17_s3_bucket_function_zip" {
  type        = "zip"
  source_file = "${path.module}/s3_function/std17_s3_bucket_function.py"
  output_path = "${path.module}/build/std17_s3_bucket_function.zip"
}


# ==================================================================
# [S3 함수] IAM 역할 / 권한
# ==================================================================

resource "aws_iam_role" "std17_s3_bucket_function_role" {
  name = "std17-s3-bucket-function-role"

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

  tags = { Name = "std17-s3-bucket-function-role" }
}

# CloudWatch Logs 기록 권한
resource "aws_iam_role_policy_attachment" "std17_s3_bucket_function_basic" {
  role       = aws_iam_role.std17_s3_bucket_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 버킷 삭제 권한 — "std17-" 버킷만 허용, Terraform 관리 버킷은 명시적 거부
resource "aws_iam_role_policy" "std17_s3_bucket_function_s3_access" {
  name = "std17-s3-bucket-function-s3-access"
  role = aws_iam_role.std17_s3_bucket_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EmptyStd17Buckets"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::std17-*", "arn:aws:s3:::std17-*/*"]
      },
      {
        Sid      = "DeleteStd17Buckets"
        Effect   = "Allow"
        Action   = ["s3:DeleteBucket"]
        Resource = "arn:aws:s3:::std17-*"
      },
      {
        Sid    = "ProtectTerraformBucket"
        Effect = "Deny"
        Action = ["s3:DeleteBucket", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# ==================================================================
# [S3 함수] Lambda 함수
# ==================================================================

resource "aws_cloudwatch_log_group" "std17_s3_bucket_function" {
  name              = "/aws/lambda/${local.s3_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "std17_s3_bucket_function" {
  function_name = local.s3_function_name
  role          = aws_iam_role.std17_s3_bucket_function_role.arn

  filename         = data.archive_file.std17_s3_bucket_function_zip.output_path
  source_code_hash = data.archive_file.std17_s3_bucket_function_zip.output_base64sha256

  handler = "std17_s3_bucket_function.lambda_handler"
  runtime = "python3.14"
  timeout = 60

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.std17_s3_bucket_function_basic,
    aws_iam_role_policy.std17_s3_bucket_function_s3_access,
    aws_cloudwatch_log_group.std17_s3_bucket_function,
  ]

  tags = { Name = local.s3_function_name }
}
