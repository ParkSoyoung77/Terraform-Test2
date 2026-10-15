variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "log_bucket_name" {
    description = "로그를 저장할 S3 버킷 이름 (storage 모듈)"
    type        = string
}

variable "log_bucket_arn" {
    description = "로그를 저장할 S3 버킷 ARN (storage 모듈)"
    type        = string
}

variable "log_prefix" {
    description = "S3 객체 키 접두사"
    type        = string
    default     = "fastapi-logs"
}