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

# ==================================================================
# EC2 보안그룹 조회/인바운드 규칙 삭제 권한 (인라인 정책)
# ==================================================================
output "ec2_sg_revoke_policy_arn" {
  description = "EC2 SG revoke policy ARN"
  value       = aws_iam_policy.std17_ec2_sg_revoke_policy.arn
}