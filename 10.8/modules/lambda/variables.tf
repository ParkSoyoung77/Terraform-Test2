variable "s3_bucket_name" {
  description = "이벤트 알림을 걸 버킷 이름"
  type        = string
}

variable "secret_name" {
  description = "Lambda가 읽을 Secrets Manager 시크릿 이름"
  type        = string
  default     = "project/db/password"
}