variable "bucket_name" {
  description = "로그 저장용 S3 버킷 이름 (전역 고유)"
  type        = string
  default     = "std17-eu-west-2-log-bucket"
}

variable "transition_ia_days" {
  description = "Standard-IA 로 전환할 일수"
  type        = number
  default     = 30
}

variable "transition_glacier_days" {
  description = "Glacier Flexible Retrieval 로 전환할 일수"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "로그 삭제 일수"
  type        = number
  default     = 365
}