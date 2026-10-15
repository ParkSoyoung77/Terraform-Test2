variable "name_prefix" {
    description = "리소스 Name 태그 접두사 (locals의 tag_header)"
    type        = string
    default     = "std17-test"
}

variable "vpc_cidr" {
    description = "VPC CIDR 블록 (/16 기준, 앞 두 옥텟으로 서브넷 CIDR 생성)"
    type        = string
    default     = "10.0.0.0/16"
}

variable "az_count" {
    description = "사용할 가용영역 개수 (리전 AZ 목록 앞에서부터)"
    type        = number
    default     = 3
}