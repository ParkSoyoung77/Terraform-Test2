locals {
  object_read_function_name = "std17-object-read"
}

# ==================================================================
# [S3 파일 함수] 배포 패키지 (boto3는 런타임 기본 포함 → 별도 설치 불필요)
#   목록(list) / 읽기(read) / 삭제(delete) / 복사(copy)
# ==================================================================

data "archive_file" "std17_object_read_zip" {
  type        = "zip"
  source_file = "${path.module}/s3_function/std17_object_read.py"
  output_path = "${path.module}/build/std17_object_read.zip"
}


# ==================================================================
# [S3 파일 함수] IAM 역할 / 권한
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

# CloudWatch Logs 기록 권한
resource "aws_iam_role_policy_attachment" "std17_object_read_basic" {
  role       = aws_iam_role.std17_object_read_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# "std17-" 버킷: 목록/읽기/삭제/복사 허용, 웹페이지 파일은 삭제/덮어쓰기 금지
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
      },
      {
        Sid      = "ManageStd17Objects" # 삭제 / 복사(대상에 쓰기)
        Effect   = "Allow"
        Action   = ["s3:DeleteObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::std17-*/*"
      },
      {
        Sid    = "ProtectWebsiteFiles" # 이 웹페이지 파일(index.html 등)은 삭제/덮어쓰기 금지
        Effect = "Deny"
        Action = ["s3:DeleteObject", "s3:PutObject"]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/index.html",
          "arn:aws:s3:::${var.s3_bucket_name}/read.html",
          "arn:aws:s3:::${var.s3_bucket_name}/error.html"
        ]
      }
    ]
  })
}

# ==================================================================
# [S3 파일 함수] Lambda 함수
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

  handler     = "std17_object_read.lambda_handler"
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
# [S3 파일 함수] Function URL (S3 웹페이지에서 직접 호출)
# ==================================================================

resource "aws_lambda_function_url" "std17_object_read_url" {
  function_name      = aws_lambda_function.std17_object_read.function_name
  authorization_type = "NONE"

  # 브라우저에서 호출하므로 CORS 필요
  # → Python 코드에서는 CORS 헤더를 넣지 않음 (중복되면 브라우저 오류)
  cors {
    allow_origins = ["*"]
    allow_methods = ["GET"] # 읽기/삭제/복사 모두 GET 쿼리스트링으로 호출
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