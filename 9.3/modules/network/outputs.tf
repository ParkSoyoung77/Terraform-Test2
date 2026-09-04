output "vpc_id" {
  description = "VPC1 ID"
  value       = aws_vpc.std17_vpc.id
}

output "public_subnet_ids" {
    value = aws_subnet.std17_public_subnet[*].id
}