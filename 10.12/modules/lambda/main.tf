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
# Pillow 레이어
#   layer/python/PIL ... 구조 → zip 안에 python/ 폴더가 최상위로 들어감
# ==================================================================

data "archive_file" "pillow_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/build/pillow_layer.zip"
}

resource "aws_lambda_layer_version" "pillow" {
  layer_name          = "std17-pillow-layer"
  filename            = data.archive_file.pillow_layer_zip.output_path
  source_code_hash    = data.archive_file.pillow_layer_zip.output_base64sha256
  compatible_runtimes = ["python3.14"]
  compatible_architectures = ["x86_64"]
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

  layers = [aws_lambda_layer_version.pillow.arn]

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

# ##################################################################
#   FinOps 함수 (eventbridge_scheduler_finops.py)
#   EventBridge Scheduler → Lambda → EC2 / RDS 시작·중지
# ##################################################################

locals {
  finops_function_name = "eventbridge_scheduler_finops"
  finops_source_file   = "${path.module}/s3_function/eventbridge_scheduler_finops.py"
}

# ==================================================================
# [FinOps] 배포 패키지
# ==================================================================

data "archive_file" "finops_zip" {
  type        = "zip"
  source_file = local.finops_source_file
  output_path = "${path.module}/build/eventbridge_scheduler_finops.zip"
}

# ==================================================================
# [FinOps] Lambda 실행 역할 / 권한
# ==================================================================

resource "aws_iam_role" "finops_lambda_role" {
  name = "${local.finops_function_name}-role"

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

  tags = { Name = "${local.finops_function_name}-role" }
}

resource "aws_iam_role_policy" "finops_lambda_policy" {
  name = "${local.finops_function_name}-policy"
  role = aws_iam_role.finops_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "EC2StartStop"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSStartStop"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================================================================
# [FinOps] Lambda 함수
# ==================================================================

resource "aws_cloudwatch_log_group" "finops" {
  name              = "/aws/lambda/${local.finops_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "finops" {
  function_name = local.finops_function_name
  role          = aws_iam_role.finops_lambda_role.arn

  filename         = data.archive_file.finops_zip.output_path
  source_code_hash = data.archive_file.finops_zip.output_base64sha256

  handler     = "eventbridge_scheduler_finops.lambda_handler" # 파일명.함수명
  runtime     = "python3.14"
  timeout     = 60 # EC2/RDS 여러 대 처리 대비
  memory_size = 128

  depends_on = [
    aws_iam_role_policy.finops_lambda_policy,
    aws_cloudwatch_log_group.finops,
  ]

  tags = { Name = local.finops_function_name }
}

# ==================================================================
# [FinOps] EventBridge Scheduler 역할 (Lambda 호출 권한)
# ==================================================================

resource "aws_iam_role" "finops_scheduler_role" {
  name = "${local.finops_function_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })

  tags = { Name = "${local.finops_function_name}-scheduler-role" }
}

resource "aws_iam_role_policy" "finops_scheduler_invoke" {
  name = "${local.finops_function_name}-scheduler-invoke"
  role = aws_iam_role.finops_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.finops.arn,         # 함수 자체
          "${aws_lambda_function.finops.arn}:*"   # 버전 / 별칭
        ]
      }
    ]
  })
}