variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "eu-west-2"   # 런던
}

variable "vpc_cidr" {
    description = "VPC CIDR 블록"
    type        = string
    default     = "10.0.0.0/16"
}

variable "az_count" {
    description = "사용할 가용영역 개수"
    type        = number
    default     = 3
}

variable "name_prefix" {
    description = "모든 리소스 Name/Tag 접두사"
    type        = string
    default     = "std17-test"
}

variable "key_name" {
    description = "EC2 키페어 이름 (SSM으로만 접속할 거면 null)"
    type        = string
    default     = "std17-key"
    nullable    = true
}

variable "ssh_allowed_cidrs" {
    description = "NAT 인스턴스(점프 호스트)에 SSH 접속을 허용할 내 PC 공인 IP (예: [\"1.2.3.4/32\"]). 빈 리스트면 SSH 차단"
    type        = list(string)
    default     = []
}