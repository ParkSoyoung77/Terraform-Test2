variable "bucket_name" {
    description = "S3 버킷 이름"
    type        = string
    default     = "std17-eu-west-2-bucket"
}

variable "api_endpoint" {
  description = "웹 페이지에서 호출할 API Gateway 주소"
  type        = string
}