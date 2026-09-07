variable "instance_ami" {
    type = string
    default = "ami-066096c472518e85a"
}

variable "instance_type" {
    type = string
    default = "t3.nano"
}

variable "name_prefix" {
    type    = string
    default = "std17-lab-"
}

variable "public_subnet_id" {
  type        = string
}

variable "ssh_sg_id" {
  description = "SSH security group ID from security module"
  type        = string
}

variable "external_alb_sg_id" {
  description = "External ALB security group ID from security module"
  type        = string
}