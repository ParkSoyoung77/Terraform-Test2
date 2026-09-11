variable "tag_header" {
    type    = string
    default = ""
}

variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "owner" {
    type    = string
    default = ""
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ssh_sg_id" {
  type = string
}

variable "external_alb_sg_id" {
  type = string
}

variable "mysql_sg_id" {
  type = string
}

variable "aws_region" {
    type = string
}

variable "principal_arn" {
    type        = string
    description = "EKS 접근을 허용할 IAM 사용자/역할의 ARN"
}