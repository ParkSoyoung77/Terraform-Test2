variable "tag_header" {
    description = "리소스 이름 접두사 (루트에서 전달, 예: std17-)"
    type        = string
    default     = ""
}

variable "key_name" {
    description = "EC2 키 페어 이름 (NAT / GitLab 공통)"
    type        = string
}

# ----------------------------------------------------
# NAT 인스턴스
# ----------------------------------------------------
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

# ----------------------------------------------------
# GitLab 인스턴스
# ----------------------------------------------------
variable "gitlab_instance_type" {
    type    = string
    default = "t3.large"
}

variable "gitlab_subnet_id" {
    description = "GitLab 인스턴스를 둘 퍼블릭 서브넷"
    type        = string
}

variable "gitlab_sg_ids" {
    type = list(string)
}

variable "gitlab_root_volume_size" {
    description = "루트 볼륨(GB) — swap 4GB + GitLab 이미지 포함"
    type        = number
    default     = 30
}

variable "gitlab_data_volume_size" {
    description = "GitLab 데이터 볼륨(GB) — /opt/gitlab 에 마운트"
    type        = number
    default     = 30
}