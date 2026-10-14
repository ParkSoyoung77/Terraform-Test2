variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "dashboard_name" {
  type    = string
  default = "std17-instance-board"
}

variable "instance_ids" {
  description = "고정 EC2 인스턴스 ID 목록 (예: NAT 인스턴스)"
  type        = list(string)
  default     = []
}

variable "asg_names" {
  description = "Auto Scaling Group 이름 목록 (compute ASG, EKS 노드그룹 ASG)"
  type        = list(string)
  default     = []
}

variable "period" {
  type    = number
  default = 300
}

variable "cpu_threshold" {
  type    = number
  default = 80
}