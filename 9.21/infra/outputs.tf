output "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    value       = var.aws_region
}

output "available_az" {
    value = data.aws_availability_zones.available_az.names
}

output "subnet_map" {
    value = local.subnet_map
}