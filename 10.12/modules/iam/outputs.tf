# ---------------------------------------------------------
# S3 FullAccess 역할 출력
# ---------------------------------------------------------
output "fullaccess_role_name" {
  description = "S3 FullAccess IAM role name"
  value       = aws_iam_role.std17_s3_fullaccess_role.name
}

output "fullaccess_role_arn" {
  description = "S3 FullAccess IAM role ARN"
  value       = aws_iam_role.std17_s3_fullaccess_role.arn
}

output "fullaccess_instance_profile_name" {
  description = "S3 FullAccess IAM instance profile name (compute 모듈에서 참조)"
  value       = aws_iam_instance_profile.std17_s3_fullaccess_profile.name
}
