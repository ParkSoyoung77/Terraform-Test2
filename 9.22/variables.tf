variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "tag_header" {
    description = "모든 리소스 Name/Tag 접두사"
    type        = string
    default     = ""
}

variable "vpc_cidr" {
    type        = string
    default     = "10.0.0.0/16"
}

variable "owner" {
    type        = string
    default     = "std17"
}