output "vpc_id" {
    description = "VPC ID"
    value       = module.network.vpc_id
}

output "nat_instance_id" {
    description = "NAT 인스턴스 ID"
    value       = module.nat_instance.nat_instance_id
}

output "nat_public_ip" {
    description = "NAT 인스턴스 퍼블릭 IP"
    value       = module.nat_instance.nat_public_ip
}

# ---------------- ALB / ASG ----------------
output "alb_url" {
    description = "nginx 접속 주소 (ALB)"
    value       = "http://${module.alb.alb_dns_name}"
}

output "asg_name" {
    description = "nginx EC2 오토스케일링 그룹 이름"
    value       = module.compute.asg_name
}

output "ami_id" {
    description = "Launch Template에 사용된 Amazon Linux 2023 AMI"
    value       = module.compute.ami_id
}

# ---------------- RDS ----------------
output "rds_mysql_endpoint" {
    description = "RDS MySQL 엔드포인트"
    value       = module.rds.db_endpoint
}

output "rds_db_subnet_group_name" {
    description = "RDS 서브넷 그룹 이름"
    value       = module.rds.db_subnet_group_name
}

output "rds_db_secret_arn" {
    description = "RDS 마스터 계정 Secrets Manager ARN"
    value       = module.rds.db_secret_arn
}

# ---------------- EKS ----------------
output "eks_cluster_name" {
    description = "EKS 클러스터 이름"
    value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
    description = "EKS API 서버 엔드포인트"
    value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
    description = "kubectl 연결 명령어"
    value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
