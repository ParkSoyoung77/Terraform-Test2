variable "name_prefix" {
    type    = string
    default = "std17-test-"
}

variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "azs" {
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}

variable "vpc_cidr" {
    type        = string
    default     = "10.0.0.0/16"
}

variable "region" {
    type        = string
    default     = "ap-northeast-3"
}

variable "subnet_cidr" {
    type        = list(list(string))
    default     = [
        ["10.0.1.0/24","10.0.2.0/24", "10.0.3.0/24"],
        ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    ]
}