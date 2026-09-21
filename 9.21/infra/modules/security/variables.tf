variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "owner" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "tag_header" {
    type    = string
    default = ""
}