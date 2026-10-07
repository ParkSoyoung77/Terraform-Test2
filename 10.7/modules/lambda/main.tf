locals {
  object_read_function_name = "std17-object-read"
}

# ==================================================================
# [오브젝트 읽기 함수] 배포 패키지 — 파일 목록(action=list) / 파일 읽기(action=read)
# ==================================================================
data "archive_file" "std17_object_read_zip" {
  type        = "zip"
  source_file = "${path.module}/s3_function/std17_object_read.py"
  output_path = "${path.module}/build/std17_object_read.zip"
}

# ==================================================================
# [오브젝트 읽기 함수] IAM 역할 / 권한 (읽기 전용)
# ==================================================================
resource "aws_iam_role" "std17_object_read_role" {
  name = "std17-object-read-role"

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

  tags = { Name = "std17-object-read-role" }
}

resource "aws_iam_role_policy_attachment" "std17_object_read_basic" {
  role       = aws_iam_role.std17_object_read_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "std17_object_read_s3_access" {
  name = "std17-object-read-s3-access"
  role = aws_iam_role.std17_object_read_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListStd17Buckets"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::std17-*",
          "arn:aws:s3:::${var.s3_bucket_name}"
        ]
      },
      {
        Sid    = "ReadStd17Objects"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::std17-*/*",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# ==================================================================
# [오브젝트 읽기 함수] Lambda 함수
# ==================================================================
resource "aws_cloudwatch_log_group" "std17_object_read" {
  name              = "/aws/lambda/${local.object_read_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "std17_object_read" {
  function_name = local.object_read_function_name
  role          = aws_iam_role.std17_object_read_role.arn

  filename         = data.archive_file.std17_object_read_zip.output_path
  source_code_hash = data.archive_file.std17_object_read_zip.output_base64sha256

  handler     = "std17_object_read.lambda_handler"   # 파일명.함수명
  runtime     = "python3.14"
  timeout     = 30
  memory_size = 256

  depends_on = [
    aws_iam_role_policy_attachment.std17_object_read_basic,
    aws_iam_role_policy.std17_object_read_s3_access,
    aws_cloudwatch_log_group.std17_object_read,
  ]

  tags = { Name = local.object_read_function_name }
}

# ==================================================================
# [오브젝트 읽기 함수] Function URL
# ==================================================================
resource "aws_lambda_function_url" "std17_object_read_url" {
  function_name      = aws_lambda_function.std17_object_read.function_name
  authorization_type = "NONE"

  # 브라우저에서 호출하므로 CORS 필요
  # → Python 코드에서는 CORS 헤더를 넣지 않음 (중복되면 브라우저 오류)
  cors {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

resource "aws_lambda_permission" "std17_object_read_url_public" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.std17_object_read.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}