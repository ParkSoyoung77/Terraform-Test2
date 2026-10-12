variable "aws_region" {
    description = "리소스를 생성할 AWS 리전 (eu-west-2 = 런던)"
    type        = string
    default     = "eu-west-2"
}

variable "owner" {
    description = "리소스 소유자 — 모든 리소스 이름 접두사(tag_header)로도 사용 (예: std17 → std17-vpc)"
    type        = string
    default     = "std17"
}

variable "vpc_cidr" {
    description = "VPC CIDR"
    type        = string
    default     = "10.0.0.0/16"
}

variable "key_name" {
    description = "EC2 키 페어 이름 (aws_region 리전에 존재해야 함)"
    type        = string
    default     = "std17-key"
}

variable "nat_instance_type" {
    description = "NAT 인스턴스 타입 (NAT 전용이라 작아도 충분)"
    type        = string
    default     = "t3.micro"
}

variable "bucket_name" {
  description = "S3 버킷 이름"
  type        = string
  default     = "std17-eu-west-2-bucket"
}