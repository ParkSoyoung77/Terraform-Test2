output "vpc_id" {
  description = "VPC1 ID"
  value       = aws_vpc.std17_lab_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.std17_public_subnet.id
}