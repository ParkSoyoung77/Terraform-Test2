output "vpc_id" {
    value = aws_vpc.this.id
}

output "public_subnet_ids" {
    value = [for k, v in aws_subnet.this : v.id if local.subnet_map[k].type == "public"]
}

output "private_subnet_ids" {
    value = [for k, v in aws_subnet.this : v.id if local.subnet_map[k].type == "private"]
}

output "cluster_subnet_ids" {
    value = [for k, v in aws_subnet.this : v.id if local.subnet_map[k].type == "cluster"]
}

output "private_route_table_ids" {
    value = { for k, v in aws_route_table.private : k => v.id }
}

output "cluster_route_table_id" {
    value = aws_route_table.cluster.id
}