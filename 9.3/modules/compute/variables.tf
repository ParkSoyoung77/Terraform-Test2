variable "instance_ami" {
    type = string
    default = "ami-066096c472518e85a"
}

variable "instance_type" {
    type = string
    default = "t3.nano"
}

variable "name_prefix" {
    description = "모든 리소스 Name/Tag 접두사"
    type        = string
    default     = "std17-test-"
}