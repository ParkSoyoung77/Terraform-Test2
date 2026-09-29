variable "tag_header" {
    description = "리소스 이름 접두사 (루트에서 전달, 예: std17-)"
    type        = string
    default     = ""
}

variable "vpc_cidr" {
    description = "VPC CIDR"
    type        = string
}