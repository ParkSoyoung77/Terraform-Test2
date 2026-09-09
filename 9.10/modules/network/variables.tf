variable "tag_header" {
    type    = string
    default = ""
}

variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = ""
}

variable "azs" {
    type        = list(string)
    default     = []
}

variable "vpc_cidr" {
    type        = string
    default     = ""
}

variable "owner" {
    type        = string
    default     = ""
}