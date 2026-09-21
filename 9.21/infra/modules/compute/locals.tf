locals {
  tag_header = var.tag_header
  ami_id     = aws_ami_from_instance.std17_nginx_ami.id
  key_name   = "std17-key"
}