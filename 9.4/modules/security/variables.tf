variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "name_prefix" {
    type    = string
    default = "std17-test-"
}