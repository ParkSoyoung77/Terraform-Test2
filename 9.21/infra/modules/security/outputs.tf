output "ssh_sg_id" {
  value = aws_security_group.std17_ssh_sg.id
}

output "external_alb_sg_id" {
  value = aws_security_group.std17_external_alb_sg.id
}

output "internal_alb_sg_id" {
  value = aws_security_group.std17_internal_alb_sg.id
}

output "mysql_sg_id" {
  value = aws_security_group.std17_mysql_sg.id
}

output "private_web_sg_id" {
  value = aws_security_group.std17_private_web_sg.id
}

output "ecr_endpoint_sg_id" {
  value = aws_security_group.std17_ecr_endpoint_sg.id
}

# ===================================================
# data "aws_security_groups" "security_groups" {
#   filter {
#     name = "tag:Name"
#     values = [
#       "${local.tag_header}external-alb-sg",
#       "${local.tag_header}ssh-sg"
#     ]
#   }
# }

# output "informaiton" {
#   value = [
#     local.vpc_id,
#     data.aws_security_groups.security_group.ids
#   ]
# }