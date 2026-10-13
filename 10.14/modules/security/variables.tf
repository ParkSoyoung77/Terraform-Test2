variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_id" {
    description = "SG를 생성할 VPC ID"
    type        = string
}

variable "vpc_cidr" {
    description = "NAT SG 인바운드 허용용 VPC CIDR"
    type        = string
}