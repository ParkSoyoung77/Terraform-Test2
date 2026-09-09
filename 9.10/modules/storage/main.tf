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
# 상태 잠금용 DynamoDB 테이블 생성
# =========================================================
resource "aws_s3_bucket" "terraform_state" {
    bucket = "std17-instructor-terraform-state-bucket"

    lifecycle {
        prevent_destroy = false 
    }

    tags={
        Name = "std17-ex-terraform-state-bucket"
    }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_dynamodb_table" "terraform_lock" {
    name = "std17-lab-lock-table"
    # DynamoDB의 관리방식(비용과 연관된 설정)
    billing_mode = "PROVISIONED"    # PAY_PER_REQUEST

    hash_key = "LockID"

    read_capacity   = 20 # 초당 4KB 데이터 읽기(RCU) => 1RCU
    write_capacity = 20 # 초당 4KB 데이터 쓰기(WCU) => 1WCU

    attribute {
        name = "LockID" # 관계형 데이터베이스의 P/K와 같은 역할
        type = "S"      # S(String), N(Number), B(Binary)
    }

}