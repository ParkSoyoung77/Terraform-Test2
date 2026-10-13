output "nat_instance_id" {
    value = aws_instance.std17_nat.id
}

output "nat_public_ip" {
    value = aws_instance.std17_nat.public_ip
}