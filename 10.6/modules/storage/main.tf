resource "aws_s3_bucket" "std17_s3_bucket" {
    bucket        = var.bucket_name
    force_destroy = true   # 객체가 남아 있어도 destroy 가능
    tags          = { Name = var.bucket_name }
}

resource "aws_s3_bucket_public_access_block" "std17_s3_bucket_access" {
    bucket                  = aws_s3_bucket.std17_s3_bucket.id
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "std17_s3_bucket_web_config" {
    bucket = aws_s3_bucket.std17_s3_bucket.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }
}

resource "aws_s3_bucket_policy" "std17_s3_bucket_policy" {
    bucket = aws_s3_bucket.std17_s3_bucket.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid       = "PublicReadGetObject"
                Effect    = "Allow"
                Principal = "*"
                Action    = "s3:GetObject"
                Resource  = "${aws_s3_bucket.std17_s3_bucket.arn}/*"
            }
        ]
    })

    depends_on = [aws_s3_bucket_public_access_block.std17_s3_bucket_access]
}

# ==================================================================
# 웹사이트 파일 업로드 (index.html 에 API 주소를 넣어서 업로드)
# ==================================================================
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.std17_s3_bucket.id
  key          = "index.html"
  content_type = "text/html; charset=utf-8"
  content      = templatefile("${path.module}/web/index.html.tftpl", {
    api_endpoint = var.api_endpoint
  })
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.std17_s3_bucket.id
  key          = "error.html"
  content_type = "text/html; charset=utf-8"
  source       = "${path.module}/web/error.html"
  etag         = filemd5("${path.module}/web/error.html")
}