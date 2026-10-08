locals {
  function_name = "std17-lambda-function"

  # lambda_function.py 위치 (파일 위치가 다르면 이 경로만 수정)
  source_file = "${path.module}/s3_function/lambda_function.py"

  # 이벤트 알림 설정
  #   ※ S3 이벤트 → Lambda 는 버킷과 Lambda 가 같은 리전이어야 함
  event_bucket_name   = var.s3_bucket_name
  event_name          = "std17-thumbnail-event"
  event_filter_prefix = "uploads/"    # 접두사
  thumbnail_prefix    = "thumbnails/" # 썸네일 저장 위치 (코드와 동일하게)
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

# uploads/ 읽기 + thumbnails/ 쓰기
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${local.function_name}-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadUploads"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${local.event_bucket_name}/${local.event_filter_prefix}*"
      },
      {
        Sid      = "WriteThumbnails"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${local.event_bucket_name}/${local.thumbnail_prefix}*"
      }
    ]
  })
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

  # Pillow 레이어 (PIL 사용 시 필수) — ARN 준비되면 주석 해제
  # layers = [var.pillow_layer_arn]

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_s3_access,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = { Name = local.function_name }
}

# ==================================================================
# [이벤트 알림] S3 → Lambda 호출 권한
#   콘솔에서 "대상: Lambda 함수" 를 고르면 자동으로 붙는 권한을 직접 만듦
# ==================================================================

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "AllowS3InvokeStd17Thumbnail"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.this.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = "arn:aws:s3:::${local.event_bucket_name}"
  source_account = data.aws_caller_identity.current.account_id
}

# ==================================================================
# [이벤트 알림] std17-thumbnail-event
#   이벤트 이름 : std17-thumbnail-event
#   접두사      : uploads/
#   이벤트 유형 : 모든 객체 생성 이벤트 (s3:ObjectCreated:*)
#   대상        : Lambda 함수 (std17-lambda-function / lambda_function.py)
#
#   ※ aws_s3_bucket_notification 은 버킷의 "모든" 이벤트 알림을 통째로 관리함
#     → 콘솔에서 같은 버킷에 만든 알림은 apply 때 지워짐
# ==================================================================

resource "aws_s3_bucket_notification" "thumbnail_event" {
  bucket = local.event_bucket_name

  lambda_function {
    id                  = local.event_name
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.event_filter_prefix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}