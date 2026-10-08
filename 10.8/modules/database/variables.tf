variable "azs" {
    type        = list(string)
    default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "mysql_sg_id" {
  type        = string
}

variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "eu-west-2"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "tag_header" {
    type    = string
    default = ""
}

variable "owner" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "secret_name" {
    description = "Secrets Manager 시크릿 이름"
    type        = string
    default     = "project/db/password"
}