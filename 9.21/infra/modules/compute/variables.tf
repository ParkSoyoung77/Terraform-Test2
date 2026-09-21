variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "vpc_id" {
  description = "보안그룹을 생성할 VPC ID"
  type        = string
}

variable "tag_header" {
    type    = string
    default = ""
}

variable "subnet_id" {
    type = string
}
variable "private_subnet_ids" {
    type = list(string)
}

variable "external_alb_sg_id" {
  type = string
}

variable "ssh_sg_id" {
  type        = string
}

variable "ecr_endpoint_sg_id" {
    description = "ECR 인터페이스 VPC 엔드포인트에 적용할 보안그룹 ID"
    type        = string
}

variable "private_route_table_ids" {
    type = map(string)
}

variable "cluster_subnet_ids" {
    type = list(string)
}

variable "cluster_route_table_id" {
    type = string
}

# ========================================
variable "instance_ami" {
    type = string
    default = "ami-0086ee55a149bd32e"
}

variable "instance_type" {
    type = string
    default = "t3.nano"
}

variable "default_version" {
    description = "Launch Template의 기본 버전 (숫자 문자열 또는 \"latest\")"
    type        = string
    default     = "latest"
}

variable "instance_profile_name" {
    description = "EC2에 부여할 IAM Instance Profile 이름 (CodeDeploy 권한 포함)"
    type        = string
}

variable "subnet_tag_type" {
  description = "ASG 인스턴스를 배치할 서브넷을 찾기 위한 tag:Type 값 (예: private)"
  type        = string
}