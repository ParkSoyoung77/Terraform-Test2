output "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    value       = var.aws_region
}

output "subnet_info" {
    description = "AWS subnet Info"
    value       = var.subnet_info[1]
}

output "tup" {
    description = "tuple"
    value       = var.tup[0]
}