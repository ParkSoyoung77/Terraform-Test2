data "aws_caller_identity" "current" {}

# ==================================================================
# [Trail] S3 버킷 정책 (CloudTrail 로그 쓰기 허용)
#   ※ aws_s3_bucket_policy 는 버킷 정책을 "통째로" 덮어씀
# ==================================================================

resource "aws_s3_bucket_policy" "trail" {
  bucket = local.trail_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${local.trail_bucket_name}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.trail_bucket_name}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# ==================================================================
# [Trail] SSE-KMS 암호화 키 (신규, 기본값)
# ==================================================================

resource "aws_kms_key" "trail" {
  description             = "${local.trail_name} log encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${local.account_id}:trail/*"
          }
        }
      },
      {
        Sid       = "AllowCloudTrailDescribeKey"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:DescribeKey"
        Resource  = "*"
      },
      {
        Sid       = "AllowAccountDecrypt"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = ["kms:Decrypt", "kms:ReEncryptFrom"]
        Resource  = "*"
        Condition = {
          StringEquals = { "kms:CallerAccount" = local.account_id }
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${local.account_id}:trail/*"
          }
        }
      }
    ]
  })

  tags = local.trail_tags
}

resource "aws_kms_alias" "trail" {
  name          = "alias/${local.trail_name}"
  target_key_id = aws_kms_key.trail.key_id
}

# ==================================================================
# [Trail] CloudWatch Logs + IAM 역할 (std17-security-trail)
# ==================================================================

resource "aws_cloudwatch_log_group" "trail" {
  name              = "aws-cloudtrail-logs-${local.trail_name}"
  retention_in_days = 7

  tags = local.trail_tags
}

resource "aws_iam_role" "trail_cw" {
  name = "std17-security-trail"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.trail_tags
}

resource "aws_iam_role_policy" "trail_cw" {
  name = "std17-security-trail-cwlogs"
  role = aws_iam_role.trail_cw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.trail.arn}:log-stream:*"
      }
    ]
  })
}

# ==================================================================
# [Trail] 추적 생성
# ==================================================================

resource "aws_cloudtrail" "security_audit" {
  name           = local.trail_name
  s3_bucket_name = local.trail_bucket_name

  # 기본값
  is_multi_region_trail         = false
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true
  kms_key_id                    = aws_kms_key.trail.arn

  # CloudWatch Logs
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.trail_cw.arn

  # 관리 이벤트 : 읽기 + 쓰기
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.trail,
    aws_iam_role_policy.trail_cw,
  ]

  tags = local.trail_tags
}