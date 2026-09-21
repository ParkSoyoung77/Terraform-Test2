output "golden_ami_id" {
  value = aws_ami_from_instance.std17_nginx_ami.id
}