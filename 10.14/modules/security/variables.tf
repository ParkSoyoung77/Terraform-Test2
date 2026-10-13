variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_id" {
    description = "SG를 생성할 VPC ID"
    type        = string
}