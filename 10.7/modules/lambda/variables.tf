variable "s3_bucket_name" {
  description = "S3 함수가 접근할 버킷 이름"
  type        = string
}

variable "secret_name" {
  description = "Lambda가 읽을 Secrets Manager 시크릿 이름"
  type        = string
  default     = "project/db/password"
}