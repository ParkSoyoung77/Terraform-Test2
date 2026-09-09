output "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    value       = var.aws_region
}

output "subnet_map" {
    value = local.subnet_map
}