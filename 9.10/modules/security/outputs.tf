output "ssh_sg_id" {
  value = aws_security_group.std17_ssh_sg.id
}

output "external_alb_sg_id" {
  value = aws_security_group.std17_external_alb_sg.id
}

output "mysql_sg_id" {
  value = aws_security_group.std17_mysql_sg.id
}
