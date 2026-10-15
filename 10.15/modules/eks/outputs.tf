output "cluster_name" {
    value = aws_eks_cluster.std17_test_eks.name
}

output "cluster_endpoint" {
    value = aws_eks_cluster.std17_test_eks.endpoint
}

output "cluster_certificate_authority_data" {
    value = aws_eks_cluster.std17_test_eks.certificate_authority[0].data
}

output "node_role_arn" {
    value = aws_iam_role.std17_test_eks_node_role.arn
}

output "cluster_primary_security_group_id" {
    description = "EKS가 클러스터 생성 시 자동으로 만든 SG (관리형 노드에 실제로 붙는 SG)"
    value       = aws_eks_cluster.std17_test_eks.vpc_config[0].cluster_security_group_id
}

output "node_asg_name" {
    value = aws_eks_node_group.std17_test_eks_nodegroup.resources[0].autoscaling_groups[0].name
}