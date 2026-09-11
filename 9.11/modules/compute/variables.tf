variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "tag_header" {
    type    = string
    default = ""
}

variable "subnet_id" {
    type = string
}
variable "private_subnet_ids" {
    type = list(string)
}

variable "external_alb_sg_id" {
  type = string
}

variable "ssh_sg_id" {
  type        = string
}

variable "eks_node_sg_id" {
    type = string
}

variable "private_route_table_ids" {
    type = map(string)
}

variable "cluster_subnet_ids" {
    type = list(string)
}

variable "cluster_route_table_id" {
    type = string
}

# ========================================
variable "instance_ami" {
    type = string
    default = "ami-0086ee55a149bd32e"
}

variable "instance_type" {
    type = string
    default = "t3.nano"
}

variable "efs_id" {
    type = string
}