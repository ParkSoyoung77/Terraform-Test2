data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==================================================================
# S3 버킷 (로그 저장용)
# ==================================================================
resource "aws_s3_bucket" "std17_log_bucket" {
  bucket        = var.bucket_name
  force_destroy = true # 실습용: 로그가 남아 있어도 destroy 가능
  tags          = { Name = var.bucket_name }
}

# 퍼블릭 액세스 전부 차단
resource "aws_s3_bucket_public_access_block" "std17_log_bucket_access" {
  bucket                  = aws_s3_bucket.std17_log_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ACL 비활성화 (버킷 소유자가 모든 객체 소유)
resource "aws_s3_bucket_ownership_controls" "std17_log_bucket_owner" {
  bucket = aws_s3_bucket.std17_log_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 기본 암호화 (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "std17_log_bucket_sse" {
  bucket = aws_s3_bucket.std17_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==================================================================
# 수명 주기: 30일 → IA, 90일 → Glacier, 365일 → 삭제
# ==================================================================
resource "aws_s3_bucket_lifecycle_configuration" "std17_log_bucket_lifecycle" {
  bucket = aws_s3_bucket.std17_log_bucket.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# ==================================================================
# 버킷 정책
#   1) CloudWatch Logs → S3 내보내기(export) 허용
#   2) HTTPS 가 아닌 요청 거부
# ==================================================================
resource "aws_s3_bucket_policy" "std17_log_bucket_policy" {
  bucket = aws_s3_bucket.std17_log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCWLogsGetBucketAcl"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.region}.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.std17_log_bucket.arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      },
      {
        Sid       = "AllowCWLogsPutObject"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.region}.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.std17_log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.std17_log_bucket.arn,
          "${aws_s3_bucket.std17_log_bucket.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.std17_log_bucket_access]
}