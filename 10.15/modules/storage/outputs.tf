output "bucket_id" {
  value = aws_s3_bucket.std17_log_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.std17_log_bucket.arn
}

output "bucket_name" {
  value = aws_s3_bucket.std17_log_bucket.bucket
}