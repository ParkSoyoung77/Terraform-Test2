output "cluster_sg_id" {
  value = aws_security_group.std17_cluster_sg.id
}

output "eks_node_sg_id" {
  value = aws_security_group.std17_eks_node_sg.id
}