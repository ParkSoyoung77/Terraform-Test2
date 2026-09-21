output "codedeploy_app_name" {
    value = aws_codedeploy_app.app.name
}

output "deployment_group_name" {
    value = aws_codedeploy_deployment_group.dg.deployment_group_name
}

output "asg_name" {
    value = aws_autoscaling_group.asg.name
}

output "asg_role_arn" {
    value = aws_iam_role.asg_node_role.arn
}

output "instance_profile_name" {
    value = aws_iam_instance_profile.asg_node_profile.name
}

output "codepipeline_name" {
    value = aws_codepipeline.codepipeline.name
}

output "github_connection_arn" {
    description = "GitHub 연결 승인이 필요한 CodeStar Connection ARN (AWS 콘솔에서 수동 승인 필요)"
    value       = aws_codestarconnections_connection.github.arn
}

output "pipeline_bucket_name" {
    value = aws_s3_bucket.pipeline_bucket.bucket
}
