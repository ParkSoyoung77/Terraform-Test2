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