output "vpc_id" {
    value = aws_vpc.this.id
}

# 인스턴스가 부팅하자마자 user data에서 dnf / docker pull 을 하므로
# 퍼블릭 서브넷 ID는 인터넷 경로(IGW 라우트 + 연결)가 준비된 뒤에 넘겨줌
output "public_subnet_ids" {
    value = [for k, v in aws_subnet.this : v.id if local.subnet_map[k].type == "public"]

    depends_on = [
        aws_route.public,
        aws_route_table_association.public
    ]
}

output "private_subnet_ids" {
    value = [for k, v in aws_subnet.this : v.id if local.subnet_map[k].type == "private"]
}

output "private_route_table_ids" {
    value = { for k, v in aws_route_table.private : k => v.id }
}

output "azs" {
    value = local.azs
}

output "subnet_map" {
    value = local.subnet_map
}