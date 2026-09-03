variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "azs" {
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}

variable "vpc_cidr" {
    type        = string
    default     = "10.0.0.0/16"
}