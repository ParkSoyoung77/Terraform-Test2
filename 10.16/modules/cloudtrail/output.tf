output "trail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.security_audit.arn
}

output "trail_log_group_name" {
  description = "CloudTrail CloudWatch Logs 그룹 이름"
  value       = aws_cloudwatch_log_group.trail.name
}

output "trail_kms_key_arn" {
  description = "CloudTrail 로그 암호화 KMS 키 ARN"
  value       = aws_kms_key.trail.arn
}