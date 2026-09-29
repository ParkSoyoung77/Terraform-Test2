output "nat_sg_id" {
    value = aws_security_group.nat.id
}

output "gitlab_sg_id" {
    value = aws_security_group.gitlab.id
}

output "ssh_sg_id" {
    value = aws_security_group.ssh.id
}

output "external_alb_sg_id" {
    value = aws_security_group.external_alb.id
}

output "internal_alb_sg_id" {
    value = aws_security_group.internal_alb.id
}