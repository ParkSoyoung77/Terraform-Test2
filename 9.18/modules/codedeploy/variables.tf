variable "tag_header" {
    description = "리소스 이름 접두사 (예: std17-)"
    type        = string
    default     = ""
}

variable "vpc_security_group_ids" {
    description = "ASG 노드 Launch Template에 적용할 보안그룹 ID 목록"
    type        = list(string)
    default     = []
}

variable "subnet_tag_type" {
    description = "ASG 대상 서브넷을 찾기 위한 Type 태그 값"
    type        = string
    default     = "cluster"
}

variable "instance_type" {
    description = "ASG에서 사용할 EC2 인스턴스 타입"
    type        = string
    default     = "t3.micro"
}

variable "asg_min_size" {
    type    = number
    default = 1
}

variable "asg_max_size" {
    type    = number
    default = 3
}

variable "asg_desired_capacity" {
    type    = number
    default = 2
}

variable "deployment_config_name" {
    description = "CodeDeploy 배포 구성 (예: CodeDeployDefault.AllAtOnce)"
    type        = string
    default     = "CodeDeployDefault.AllAtOnce"
}

variable "codedeploy_agent_region" {
    description = "CodeDeploy Agent 설치 스크립트를 받아올 리전 (원본은 ap-south-1로 하드코딩되어 있었음)"
    type        = string
    default     = "ap-northeast-3"
}