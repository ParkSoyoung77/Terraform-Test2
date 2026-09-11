variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "tag_header" {
    type    = string
    default = ""
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "external_alb_sg_id" {
  type = string
}

variable "private_route_table_id" {
    type = string
}