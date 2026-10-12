variable "tag_header" {
    description = "리소스 이름 접두사 (루트에서 전달, 예: std17-)"
    type        = string
    default     = ""
}

variable "vpc_cidr" {
    description = "VPC CIDR"
    type        = string
}

variable "az_count" {
  description = "사용할 가용 영역 개수 (앞에서부터: a, b, c ...)"
  type        = number
  default     = 3
}