variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_id" {
    type = string
}

variable "public_subnet_ids" {
    type = list(string)
}

variable "security_group_id" {
    type = string
}
