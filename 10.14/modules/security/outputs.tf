output "alb_sg_id" {
    description = "ALB 보안그룹 ID"
    value       = aws_security_group.std17_alb_sg.id
}

output "ec2_sg_id" {
    description = "EC2(nginx docker) 보안그룹 ID"
    value       = aws_security_group.std17_ec2_sg.id
}

output "rds_sg_id" {
    description = "RDS 보안그룹 ID"
    value       = aws_security_group.std17_rds_sg.id
}
