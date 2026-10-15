variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "private_subnet_ids" {
    description = "RDS 서브넷 그룹에 사용할 프라이빗 서브넷 ID 리스트"
    type        = list(string)
}

variable "security_group_id" {
    type = string
}

variable "engine_version" {
    description = "MySQL 버전 (메이저만 쓰면 해당 메이저의 기본 마이너 버전으로 생성)"
    type        = string
    default     = "8.4"
}

variable "instance_class" {
    type    = string
    default = "db.t4g.micro"
}

variable "db_name" {
    description = "생성할 데이터베이스 이름"
    type        = string
    default     = "rdsdb"
}

variable "master_username" {
    type    = string
    default = "adm"
}
