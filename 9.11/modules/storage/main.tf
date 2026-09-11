# =========================================================
# S3 생성
# =========================================================
resource "aws_s3_bucket" "std17_ex_bucket" {
    bucket = "std17-ex-bucket"

    # 버킷에 객체가 존재하더라도 강제 삭제 허용(기본값: false)
    force_destroy       = false

    # 객체 잠금
    object_lock_enabled = false # default(false)

    tags={
        Name = "std17-ex-bucket"
    }
}

resource "aws_s3_bucket_versioning" "std17_ex_bucket_versioning" {
    bucket = aws_s3_bucket.std17_ex_bucket.id
    versioning_configuration {
        status = "Disabled" # "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_ex_bucket_access" {
    bucket = aws_s3_bucket.std17_ex_bucket.id

    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "std17_ex_bucket_website" {
    bucket = aws_s3_bucket.std17_ex_bucket.id

    index_document {
        suffix = "index.html"
    }
    error_document {
        key    = "error.html"
    }
}

resource "aws_s3_bucket_policy" "std17_ex_bucket_policy" {

    bucket = aws_s3_bucket.std17_ex_bucket.id

    depends_on = [
        aws_s3_bucket_public_access_block.std17_ex_bucket_access
    ]

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid       = "PublicReadGetObject"
                Effect    = "Allow"
                Principal = "*"
                Action    = "s3:GetObject"
                Resource  = "${aws_s3_bucket.std17_ex_bucket.arn}/*"
            }
        ]
    })
}

# =========================================================
# Terraform State 저장용 S3 버킷
# =========================================================
resource "aws_s3_bucket" "std17_tfstate_bucket" {
    bucket = "std17-tfstate-bucket"

    force_destroy       = false
    object_lock_enabled = false

    tags={
        Name = "std17-tfstate-bucket"
    }
}

resource "aws_s3_bucket_versioning" "std17_tfstate_bucket_versioning" {
    bucket = aws_s3_bucket.std17_tfstate_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_tfstate_bucket_access" {
    bucket = aws_s3_bucket.std17_tfstate_bucket.id

    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
}

# =========================================================
# 로그 보관용 S3 버킷
# =========================================================
resource "aws_s3_bucket" "std17_log_bucket" {
    bucket = "std17-log-bucket"

    force_destroy       = false
    object_lock_enabled = false

    tags={
        Name = "std17-log-bucket"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_log_bucket_access" {
    bucket = aws_s3_bucket.std17_log_bucket.id

    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
}

# =========================================================
# EFS
# =========================================================
resource "aws_efs_file_system" "std17_efs" {
    creation_token = "${local.tag_header}efs"

    tags = {
        Name = "${local.tag_header}efs"
    }
}

resource "aws_security_group" "std17_efs_sg" {
    name = "${local.tag_header}efs-sg"
    description = "Security group for EFS mount targets"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 2049
        to_port     = 2049
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.tag_header}efs-sg"
    }
}

resource "aws_efs_mount_target" "std17_efs_mount" {
    count = length(var.private_subnet_ids)

    file_system_id  = aws_efs_file_system.std17_efs.id
    subnet_id       = var.private_subnet_ids[count.index]
    security_groups = [aws_security_group.std17_efs_sg.id]
}