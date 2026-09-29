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

# ----------------------------------------------------
# GitLab 인스턴스 — apply 후 이 주소로 접속 (따로 입력할 필요 없음)
# ----------------------------------------------------
output "gitlab_public_ip" {
    value = module.compute.gitlab_public_ip
}

output "gitlab_url" {
    value = module.compute.gitlab_url
}

output "gitlab_ssh_clone_example" {
    value = "ssh://git@${module.compute.gitlab_public_ip}:2222/<group>/<project>.git"
}