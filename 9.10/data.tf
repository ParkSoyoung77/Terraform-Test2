data "aws_availability_zones" "available_az" {
    state = "available"
}

output "available_az" {
    value = data.aws_availability_zones.available_az.names
}
