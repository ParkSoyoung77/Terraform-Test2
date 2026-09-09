variable "azs" {
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}

variable "mysql_sg_id" {
  type        = string
}

variable "lambda_sg_id" {
  type        = string  
}

variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "name_prefix" {
  description = "리소스 이름 앞에 붙일 접두사"
  type        = string
  default     = "std17-"
}