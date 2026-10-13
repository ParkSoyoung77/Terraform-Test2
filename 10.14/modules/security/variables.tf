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

variable "ssh_allowed_cidrs" {
    description = "NAT 인스턴스 SSH(22) 허용 CIDR 리스트 (빈 리스트면 규칙 생성 안 함)"
    type        = list(string)
    default     = []
}