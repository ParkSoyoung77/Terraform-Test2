variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "private_subnet_ids" {
    description = "EKS 전용 프라이빗 서브넷 ID 리스트 (AZ 3개)"
    type        = list(string)
}

variable "cluster_name" {
    type    = string
    default = "std17-test-eks-cluster"
}

variable "cluster_version" {
    type    = string
    default = "1.34"
}

variable "endpoint_public_access" {
    type    = bool
    default = true
}

variable "endpoint_public_access_cidrs" {
    type    = list(string)
    default = ["0.0.0.0/0"]
}

variable "node_group_name" {
    type    = string
    default = "std17-test-eks-nodegroup"
}

variable "node_instance_types" {
    type    = list(string)
    default = ["t3.small"]
}

variable "node_disk_size" {
    type    = number
    default = 20
}

variable "node_desired_size" {
    type    = number
    default = 1
}

variable "node_min_size" {
    type    = number
    default = 1
}

variable "node_max_size" {
    type    = number
    default = 2
}

variable "addon_versions" {
    type    = map(string)
    default = {}
}

variable "admin_principal_arns" {
    description = "미지정 시 apply를 실행하는 계정이 자동으로 클러스터 admin 권한을 받음"
    type        = list(string)
    default     = []
}

variable "node_ssh_key_name" {
    description = "노드 SSH 키페어 이름 (null이면 노드 SSH 비활성화)"
    type        = string
    default     = null
}

variable "node_ssh_source_sg_ids" {
    description = "노드 SSH(22)를 허용할 보안그룹 ID 리스트 (NAT 점프 호스트 SG)"
    type        = list(string)
    default     = []
}