output "nat_instance_id" {
    value = aws_instance.nat.id
}

output "nat_public_ip" {
    value = aws_instance.nat.public_ip
}

output "gitlab_instance_id" {
    value = aws_instance.gitlab.id
}

output "gitlab_public_ip" {
    value = aws_eip.gitlab.public_ip
}

output "gitlab_url" {
    value = "http://${aws_eip.gitlab.public_ip}"
}