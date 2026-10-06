locals {
  function_name           = "std17-lambda-function"
  s3_function_name        = "std17-s3-bucket-function"
  s3_search_function_name = "std17-s3-bucket-search"
  s3_create_function_name = "std17-s3-bucket-create"
  s3_delete_function_name = "std17-s3-bucket-delete"
}

# # ==================================================================
# # Lambda 배포 패키지 빌드 (pymysql은 기본 런타임에 없으므로 함께 패키징)
# # ==================================================================

# resource "null_resource" "install_lambda_deps" {
#   triggers = {
#     requirements_hash = filemd5("${path.module}/lambda/requirements.txt")
#     source_hash       = filemd5("${path.module}/lambda/lambda_function.py")
#   }

#   provisioner "local-exec" {
#     command = "pip install -r ${path.module}/lambda/requirements.txt -t ${path.module}/lambda --upgrade --no-cache-dir --break-system-packages"
#   }
# }

# data "archive_file" "std17_lambda_function_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda"
#   output_path = "${path.module}/build/lambda_function.zip"
#   excludes    = ["requirements.txt"]

#   depends_on = [null_resource.install_lambda_deps]
# }

# # ==================================================================
# # IAM 역할 / 권한
# # ==================================================================

# resource "aws_iam_role" "std17_lambda_role" {
#   name = "std17-lambda-db-check-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = { Service = "lambda.amazonaws.com" }
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = { Name = "std17-lambda-db-check-role" }
# }

# resource "aws_iam_role_policy_attachment" "std17_lambda_vpc_access" {
#   role       = aws_iam_role.std17_lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
# }

# resource "aws_iam_role_policy" "std17_lambda_secrets_access" {
#   name = "std17-lambda-secrets-access"
#   role = aws_iam_role.std17_lambda_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid      = "Statement1"
#         Effect   = "Allow"
#         Action   = ["secretsmanager:GetSecretValue"]
#         Resource = var.db_secret_arn
#       }
#     ]
#   })
# }

# # ==================================================================
# # Lambda 함수
# # ==================================================================

# resource "aws_cloudwatch_log_group" "std17_lambda_function" {
#   name              = "/aws/lambda/${local.function_name}"
#   retention_in_days = 7
# }

# resource "aws_lambda_function" "std17_lambda_function" {
#   function_name = local.function_name
#   role          = aws_iam_role.std17_lambda_role.arn

#   filename         = data.archive_file.std17_lambda_function_zip.output_path
#   source_code_hash = data.archive_file.std17_lambda_function_zip.output_base64sha256

#   handler = "lambda_function.lambda_handler"
#   runtime = "python3.14"
#   timeout = 10

#   vpc_config {
#     subnet_ids         = var.private_subnet_ids
#     security_group_ids = [var.security_group_id]
#   }

#   environment {
#     variables = {
#       DB_SECRET_NAME = var.db_secret_arn
#       DB_HOST        = var.db_host
#       DB_NAME        = var.db_name
#       DB_PORT        = "3306"
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.std17_lambda_vpc_access,
#     aws_iam_role_policy.std17_lambda_secrets_access,
#     aws_cloudwatch_log_group.std17_lambda_function,
#   ]

#   tags = { Name = local.function_name }
# }

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

# 대상 버킷 접근 권한
resource "aws_iam_role_policy" "std17_s3_bucket_function_s3_access" {
  name = "std17-s3-bucket-function-s3-access"
  role = aws_iam_role.std17_s3_bucket_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # list_buckets() 호출용 — 버킷 단위로 제한 불가하여 "*" 사용
        Sid      = "ListAllBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = "*"
      },
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Sid      = "ObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
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
  timeout = 10

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

# # ==================================================================
# # [S3 검색 함수] 배포 패키지
# # ==================================================================

# data "archive_file" "std17_s3_bucket_search_zip" {
#   type        = "zip"
#   source_file = "${path.module}/s3_function/std17_s3_bucket_search.py"
#   output_path = "${path.module}/build/std17_s3_bucket_search.zip"
# }

# # ==================================================================
# # [S3 검색 함수] Lambda 함수 (IAM 역할은 S3 함수 역할 재사용)
# # ==================================================================

# resource "aws_cloudwatch_log_group" "std17_s3_bucket_search" {
#   name              = "/aws/lambda/${local.s3_search_function_name}"
#   retention_in_days = 7
# }

# resource "aws_lambda_function" "std17_s3_bucket_search" {
#   function_name = local.s3_search_function_name
#   role          = aws_iam_role.std17_s3_bucket_function_role.arn

#   filename         = data.archive_file.std17_s3_bucket_search_zip.output_path
#   source_code_hash = data.archive_file.std17_s3_bucket_search_zip.output_base64sha256

#   handler = "std17_s3_bucket_search.lambda_handler"
#   runtime = "python3.14"
#   timeout = 10

#   environment {
#     variables = {
#       BUCKET_NAME = var.s3_bucket_name
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.std17_s3_bucket_function_basic,
#     aws_iam_role_policy.std17_s3_bucket_function_s3_access,
#     aws_cloudwatch_log_group.std17_s3_bucket_search,
#   ]

#   tags = { Name = local.s3_search_function_name }
# }

# # ==================================================================
# # [S3 생성 함수] 배포 패키지
# # ==================================================================

# data "archive_file" "std17_s3_bucket_create_zip" {
#   type        = "zip"
#   source_file = "${path.module}/s3_function/std17_s3_bucket_create.py"
#   output_path = "${path.module}/build/std17_s3_bucket_create.zip"
# }

# # ==================================================================
# # [S3 생성 함수] IAM 역할 / 권한 (생성 권한은 이 함수에만 부여)
# # ==================================================================

# resource "aws_iam_role" "std17_s3_bucket_create_role" {
#   name = "std17-s3-bucket-create-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = { Service = "lambda.amazonaws.com" }
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = { Name = "std17-s3-bucket-create-role" }
# }

# # CloudWatch Logs 기록 권한
# resource "aws_iam_role_policy_attachment" "std17_s3_bucket_create_basic" {
#   role       = aws_iam_role.std17_s3_bucket_create_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# # 버킷 생성 권한 — "std17-" 으로 시작하는 버킷만 허용
# resource "aws_iam_role_policy" "std17_s3_bucket_create_access" {
#   name = "std17-s3-bucket-create-access"
#   role = aws_iam_role.std17_s3_bucket_create_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid      = "CreateStd17Buckets"
#         Effect   = "Allow"
#         Action   = ["s3:CreateBucket"]
#         Resource = "arn:aws:s3:::std17-*"
#       },
#       {
#         # 생성 전 존재 여부 확인(head_bucket)용
#         Sid      = "CheckStd17Buckets"
#         Effect   = "Allow"
#         Action   = ["s3:ListBucket"]
#         Resource = "arn:aws:s3:::std17-*"
#       }
#     ]
#   })
# }

# # ==================================================================
# # [S3 생성 함수] Lambda 함수
# # ==================================================================

# resource "aws_cloudwatch_log_group" "std17_s3_bucket_create" {
#   name              = "/aws/lambda/${local.s3_create_function_name}"
#   retention_in_days = 7
# }

# resource "aws_lambda_function" "std17_s3_bucket_create" {
#   function_name = local.s3_create_function_name
#   role          = aws_iam_role.std17_s3_bucket_create_role.arn

#   filename         = data.archive_file.std17_s3_bucket_create_zip.output_path
#   source_code_hash = data.archive_file.std17_s3_bucket_create_zip.output_base64sha256

#   handler = "std17_s3_bucket_create.lambda_handler"
#   runtime = "python3.14"
#   timeout = 10

#   depends_on = [
#     aws_iam_role_policy_attachment.std17_s3_bucket_create_basic,
#     aws_iam_role_policy.std17_s3_bucket_create_access,
#     aws_cloudwatch_log_group.std17_s3_bucket_create,
#   ]

#   tags = { Name = local.s3_create_function_name }
# }

# # ==================================================================
# # [S3 삭제 함수] 배포 패키지
# # ==================================================================

# data "archive_file" "std17_s3_bucket_delete_zip" {
#   type        = "zip"
#   source_file = "${path.module}/s3_function/std17_s3_bucket_delete.py"
#   output_path = "${path.module}/build/std17_s3_bucket_delete.zip"
# }

# # ==================================================================
# # [S3 삭제 함수] IAM 역할 / 권한 (삭제 권한은 이 함수에만 부여)
# # ==================================================================

# resource "aws_iam_role" "std17_s3_bucket_delete_role" {
#   name = "std17-s3-bucket-delete-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = { Service = "lambda.amazonaws.com" }
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = { Name = "std17-s3-bucket-delete-role" }
# }

# # CloudWatch Logs 기록 권한
# resource "aws_iam_role_policy_attachment" "std17_s3_bucket_delete_basic" {
#   role       = aws_iam_role.std17_s3_bucket_delete_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# # 버킷 삭제 권한 — "std17-" 버킷만 허용, Terraform 관리 버킷은 명시적 거부
# resource "aws_iam_role_policy" "std17_s3_bucket_delete_access" {
#   name = "std17-s3-bucket-delete-access"
#   role = aws_iam_role.std17_s3_bucket_delete_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         # 버킷 비우기용: 객체 목록 조회 + 객체 삭제
#         Sid      = "EmptyStd17Buckets"
#         Effect   = "Allow"
#         Action   = ["s3:ListBucket", "s3:DeleteObject"]
#         Resource = ["arn:aws:s3:::std17-*", "arn:aws:s3:::std17-*/*"]
#       },
#       {
#         Sid      = "DeleteStd17Buckets"
#         Effect   = "Allow"
#         Action   = ["s3:DeleteBucket"]
#         Resource = "arn:aws:s3:::std17-*"
#       },
#       {
#         # Deny는 Allow보다 우선 → 기본 버킷은 어떤 경우에도 비우기/삭제 불가
#         Sid    = "ProtectTerraformBucket"
#         Effect = "Deny"
#         Action = ["s3:DeleteBucket", "s3:DeleteObject"]
#         Resource = [
#           "arn:aws:s3:::${var.s3_bucket_name}",
#           "arn:aws:s3:::${var.s3_bucket_name}/*"
#         ]
#       }
#     ]
#   })
# }

# # ==================================================================
# # [S3 삭제 함수] Lambda 함수
# # ==================================================================

# resource "aws_cloudwatch_log_group" "std17_s3_bucket_delete" {
#   name              = "/aws/lambda/${local.s3_delete_function_name}"
#   retention_in_days = 7
# }

# resource "aws_lambda_function" "std17_s3_bucket_delete" {
#   function_name = local.s3_delete_function_name
#   role          = aws_iam_role.std17_s3_bucket_delete_role.arn

#   filename         = data.archive_file.std17_s3_bucket_delete_zip.output_path
#   source_code_hash = data.archive_file.std17_s3_bucket_delete_zip.output_base64sha256

#   handler = "std17_s3_bucket_delete.lambda_handler"
#   runtime = "python3.14"
#   timeout = 60   # 객체가 많은 버킷을 비우는 시간 고려

#   environment {
#     variables = {
#       PROTECTED_BUCKET = var.s3_bucket_name
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.std17_s3_bucket_delete_basic,
#     aws_iam_role_policy.std17_s3_bucket_delete_access,
#     aws_cloudwatch_log_group.std17_s3_bucket_delete,
#   ]

#   tags = { Name = local.s3_delete_function_name }
# }