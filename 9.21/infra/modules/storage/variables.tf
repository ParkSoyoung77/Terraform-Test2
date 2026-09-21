variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "tag_header" {
    type    = string
    default = ""
}

variable "vpc_cidr" {
    type = string
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "owner" {
  description = "리소스 이름에 붙일 소유자 prefix"
  type        = string
  default     = ""
}