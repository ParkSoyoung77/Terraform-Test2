output "ec2_role_name" {
    description = "EC2 IAM 역할 이름"
    value       = aws_iam_role.std17_ec2_role.name
}

output "ec2_role_arn" {
    description = "EC2 IAM 역할 ARN"
    value       = aws_iam_role.std17_ec2_role.arn
}

output "ec2_instance_profile_name" {
    description = "EC2 인스턴스 프로파일 이름"
    value       = aws_iam_instance_profile.std17_ec2_profile.name
}