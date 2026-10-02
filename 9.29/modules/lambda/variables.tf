variable "private_subnet_ids" {
    description = "Lambda를 배치할 프라이빗 서브넷 ID 목록"
    type        = list(string)
}

variable "security_group_id" {
    description = "Lambda에 붙일 보안 그룹 ID"
    type        = string
}

variable "db_secret_arn" {
    description = "DB 비밀번호가 저장된 Secrets Manager ARN"
    type        = string
}

variable "db_host" {
    description = "DB 접속 호스트 (RDS Proxy 엔드포인트)"
    type        = string
}

variable "db_name" {
    description = "접속할 데이터베이스 이름"
    type        = string
}