variable "trail_name" {
  description = "CloudTrail 추적 이름"
  type        = string
  default     = "std17-security-audit-trail"
}

variable "trail_bucket_name" {
  description = "CloudTrail 로그를 저장할 기존 S3 버킷 이름"
  type        = string
}

variable "owner" {
  description = "Owner 태그 값"
  type        = string
  default     = "std17"
}