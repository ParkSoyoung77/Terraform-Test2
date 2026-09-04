data "aws_availability_zones" "available_az" {
    state = "available"
}

output "available_az" {
    value = data.aws_availability_zones.available_az.names
}

data "aws_vpc" "vpc_id" {
    filter {
        name  = "tag:Name"
        values = ["std17-test-vpc"]
    }
}

output "vpc_id" {
    value = data.aws_vpc.vpc_id.id
}