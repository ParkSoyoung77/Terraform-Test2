variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "tag_header" {
    type    = string
    default = ""
}