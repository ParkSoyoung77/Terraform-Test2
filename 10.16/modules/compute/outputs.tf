output "asg_name" {
    description = "nginx EC2 오토스케일링 그룹 이름"
    value       = aws_autoscaling_group.std17_nginx_asg.name
}

output "launch_template_id" {
    description = "nginx 시작 템플릿 ID"
    value       = aws_launch_template.std17_nginx.id
}

output "ami_id" {
    description = "사용된 Amazon Linux 2023 AMI ID"
    value       = data.aws_ami.std17_al2023.id
}
