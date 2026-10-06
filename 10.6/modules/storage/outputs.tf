output "bucket_id" {
    value = aws_s3_bucket.std17_s3_bucket.id
}

output "bucket_arn" {
    value = aws_s3_bucket.std17_s3_bucket.arn
}

output "bucket_name" {
    value = aws_s3_bucket.std17_s3_bucket.bucket
}

# output "website_endpoint" {
#     value = aws_s3_bucket_website_configuration.std17_s3_bucket_web_config.website_endpoint
# }
output "website_endpoint" {
  value = "http://${aws_s3_bucket_website_configuration.std17_s3_bucket_web_config.website_endpoint}"
}