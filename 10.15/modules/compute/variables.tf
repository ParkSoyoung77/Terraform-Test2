variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "subnet_ids" {
    description = "ASG가 사용할 서브넷 ID 리스트 (프라이빗 서브넷, NAT 경유로 이미지 pull)"
    type        = list(string)
}

variable "security_group_id" {
    description = "EC2에 붙일 보안그룹 ID (security 모듈의 ec2_sg_id)"
    type        = string
}

variable "instance_profile_name" {
    description = "EC2에 연결할 인스턴스 프로파일 이름 (iam 모듈의 ec2_instance_profile_name)"
    type        = string
}

variable "key_name" {
    description = "EC2 SSH 접속용 키페어 이름 (null이면 키페어 없이 생성, SSM으로 접속)"
    type        = string
    default     = null
}

variable "instance_type" {
    description = "nginx 컨테이너를 실행할 EC2 인스턴스 유형"
    type        = string
    default     = "t3.micro"
}

variable "root_volume_size" {
    description = "루트 EBS 볼륨 크기(GB)"
    type        = number
    default     = 10
}

variable "asg_min_size" {
    type    = number
    default = 1
}

variable "asg_desired_capacity" {
    type    = number
    default = 1
}

variable "asg_max_size" {
    type    = number
    default = 3
}

variable "alb_target_group_arn" {
    description = "ASG를 연결할 ALB 타겟그룹 ARN (alb 모듈의 target_group_arn)"
    type        = string
}

variable "aws_region" {
    description = "FastAPI boto3 클라이언트 리전 (config.json에 기록)"
    type        = string
}

variable "lambda_function_name" {
    description = "FastAPI가 호출할 로그 저장 Lambda 이름"
    type        = string
}