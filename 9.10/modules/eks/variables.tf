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

variable "image_id" {
    type = string
    default = ""
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
