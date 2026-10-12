variable "vpc_id" {
    description = "보안그룹을 생성할 VPC ID"
    type        = string
}

variable "vpc_cidr" {
    description = "VPC CIDR (NAT / 내부 통신 허용 범위)"
    type        = string
}

variable "tag_header" {
    description = "리소스 이름 접두사 (루트에서 전달, 예: std17-)"
    type        = string
    default     = ""
}

variable "admin_cidr_blocks" {
    description = "SSH(22) 접속 허용 범위 — 가능하면 내 IP/32 로 좁히기"
    type        = list(string)
    default     = ["0.0.0.0/0"]
}