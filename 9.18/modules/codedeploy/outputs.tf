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