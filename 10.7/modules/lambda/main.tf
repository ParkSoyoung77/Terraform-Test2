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
    allow_methods = ["*"] # 읽기/삭제/복사 모두 GET 쿼리스트링으로 호출
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


# ==================================================================
# [S3 이벤트 함수] 배포 패키지
# ==================================================================

data "archive_file" "std17_bucket_event_zip" {
  type        = "zip"
  source_file = "${path.module}/s3_function/std17_bucket_event.py"
  output_path = "${path.module}/build/std17_bucket_event.zip"
}

# ==================================================================
# [S3 이벤트 함수] IAM 역할 / 권한
# ==================================================================

resource "aws_iam_role" "std17_bucket_event_role" {
  name = "std17-bucket-event-role"

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

  tags = { Name = "std17-bucket-event-role" }
}

# CloudWatch Logs 기록 권한
resource "aws_iam_role_policy_attachment" "std17_bucket_event_basic" {
  role       = aws_iam_role.std17_bucket_event_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# upload/ 읽기 + backup/ 쓰기만 허용 (copy_object = 원본 GetObject + 대상 PutObject)
resource "aws_iam_role_policy" "std17_bucket_event_s3_access" {
  name = "std17-bucket-event-s3-access"
  role = aws_iam_role.std17_bucket_event_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadUploadObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectTagging"]
        Resource = "arn:aws:s3:::${local.event_bucket_name}/${local.event_filter_prefix}*"
      },
      {
        Sid      = "WriteBackupObjects"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:PutObjectTagging"]
        Resource = "arn:aws:s3:::${local.event_bucket_name}/${local.event_target_prefix}*"
      }
    ]
  })
}

# ==================================================================
# [S3 이벤트 함수] Lambda 함수
# ==================================================================

resource "aws_cloudwatch_log_group" "std17_bucket_event" {
  name              = "/aws/lambda/${local.bucket_event_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "std17_bucket_event" {
  function_name = local.bucket_event_function_name
  role          = aws_iam_role.std17_bucket_event_role.arn

  filename         = data.archive_file.std17_bucket_event_zip.output_path
  source_code_hash = data.archive_file.std17_bucket_event_zip.output_base64sha256

  handler     = "std17_bucket_event.lambda_handler"
  runtime     = "python3.14"
  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      SOURCE_PREFIX = local.event_filter_prefix
      TARGET_PREFIX = local.event_target_prefix
      TARGET_BUCKET = "" # 비우면 같은 버킷에 복사
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.std17_bucket_event_basic,
    aws_iam_role_policy.std17_bucket_event_s3_access,
    aws_cloudwatch_log_group.std17_bucket_event,
  ]

  tags = { Name = local.bucket_event_function_name }
}

# ##################################################################
#   S3 이벤트 알림 (std17-auto-copy) + std17_bucket_event 함수
#   upload/ 에 객체가 생성되면 → std17-bucket-event Lambda 실행 → backup/ 으로 복사
# ##################################################################

locals {
  bucket_event_function_name = "std17-bucket-event"

  # 이벤트 알림을 걸 버킷 (var.event_bucket_name 을 비우면 var.s3_bucket_name 사용)
  #   ※ S3 이벤트 → Lambda 는 버킷과 Lambda 가 같은 리전이어야 함
  event_bucket_name = var.event_bucket_name != "" ? var.event_bucket_name : var.s3_bucket_name

  event_filter_prefix = "upload/" # 접두사
  event_filter_suffix = ""        # 접미사 (예: ".jpg") — 비우면 모든 파일
  event_target_prefix = "backup/" # 복사될 위치
}

# ==================================================================
# [이벤트 알림] S3 → Lambda 호출 권한
#   콘솔에서 "대상: Lambda 함수" 를 고르면 자동으로 붙는 권한을 직접 만듦
# ==================================================================

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "std17_bucket_event_allow_s3" {
  statement_id   = "AllowS3InvokeStd17AutoCopy"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.std17_bucket_event.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = "arn:aws:s3:::${local.event_bucket_name}"
  source_account = data.aws_caller_identity.current.account_id
}

# ==================================================================
# [이벤트 알림] std17-auto-copy
#   이벤트 이름 : std17-auto-copy
#   접두사      : upload/
#   이벤트 유형 : 모든 객체 생성 이벤트 (s3:ObjectCreated:*)
#   대상        : Lambda 함수 (std17-bucket-event)
#
#   ※ aws_s3_bucket_notification 은 버킷의 "모든" 이벤트 알림을 통째로 관리함
#     → 콘솔에서 같은 버킷에 만든 알림은 apply 때 지워짐 (콘솔에서는 만들지 말 것)
# ==================================================================

resource "aws_s3_bucket_notification" "std17_auto_copy" {
  bucket = local.event_bucket_name

  lambda_function {
    id                  = "std17-auto-copy"
    lambda_function_arn = aws_lambda_function.std17_bucket_event.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.event_filter_prefix
    filter_suffix       = local.event_filter_suffix != "" ? local.event_filter_suffix : null
  }

  depends_on = [aws_lambda_permission.std17_bucket_event_allow_s3]
}