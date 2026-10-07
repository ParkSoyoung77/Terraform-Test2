output "aws_region" {
    description = "리소스를 생성한 AWS 리전"
    value       = var.aws_region
}

output "available_az" {
    value = module.network.azs
}

output "subnet_map" {
    value = module.network.subnet_map
}

# ----------------------------------------------------
# NAT 인스턴스
# ----------------------------------------------------
output "nat_instance_id" {
    value = module.compute.nat_instance_id
}

output "nat_public_ip" {
    description = "프라이빗 서브넷의 외부 통신이 나가는 IP"
    value       = module.compute.nat_public_ip
}

# ======================================================
output "api_endpoint" {
    value = module.apigateway.api_endpoint
}

output "website_endpoint" {
    value = module.storage.website_endpoint
}