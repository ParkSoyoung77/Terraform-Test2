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
# S3 엔드포인트 설정
# =========================================================
# 1. 서비스 데이터 소스 정의 
data "aws_vpc_endpoint_service" "s3" {
    service         = "s3"
    service_type    = "Gateway"
}

# 2. 엔드포인트 생성 및 연결
resource "aws_vpc_endpoint" "s3_endpoint" {
    vpc_id            = var.vpc_id
    service_name      = data.aws_vpc_endpoint_service.s3.service_name

    vpc_endpoint_type = "Gateway"

    route_table_ids   = [var.private_route_table_id]

    tags = { Name = "${local.tag_header}s3-endpoint"}
}