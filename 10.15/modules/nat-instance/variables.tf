variable "name_prefix" {
    description = "리소스 Name 태그 접두사"
    type        = string
    default     = "std17-test"
}

variable "key_name" {
    description = "EC2 키 페어 이름 (null이면 키페어 없이 생성)"
    type        = string
    default     = null
}

variable "instance_profile_name" {
    description = "SSM 접속용 인스턴스 프로파일 (null이면 미연결)"
    type        = string
    default     = null
}

variable "nat_instance_type" {
    type    = string
    default = "t3.micro"
}

variable "nat_subnet_id" {
    description = "NAT 인스턴스를 둘 퍼블릭 서브넷"
    type        = string
}

variable "nat_sg_ids" {
    type = list(string)
}

variable "private_route_table_ids" {
    description = "0.0.0.0/0 → NAT 인스턴스 경로를 추가할 프라이빗 라우팅 테이블 (key → id)"
    type        = map(string)
}