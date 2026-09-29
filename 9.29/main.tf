# ====================================================
# 공통 값 — 이름 접두사를 한 곳에서 만들어 모든 모듈에 동일하게 전달
# ====================================================
locals {
    tag_header = var.owner == "" ? "" : "${var.owner}-" # 예: "std17-"
}

# ====================================================
# 네트워크: VPC / 서브넷 / IGW / 라우팅 테이블 / S3 엔드포인트
# ====================================================
module "network" {
    source = "./modules/network"

    tag_header = local.tag_header
    vpc_cidr   = var.vpc_cidr
}

# ====================================================
# 보안 그룹: NAT / GitLab / SSH / ALB
# ====================================================
module "security" {
    source = "./modules/security"

    tag_header = local.tag_header
    vpc_id     = module.network.vpc_id
    vpc_cidr   = var.vpc_cidr
}

# ====================================================
# 컴퓨트: NAT 인스턴스 + GitLab 인스턴스 (분리)
# ====================================================
module "compute" {
    source = "./modules/compute"

    tag_header = local.tag_header
    key_name   = var.key_name

    # NAT 인스턴스
    nat_instance_type       = var.nat_instance_type
    nat_subnet_id           = module.network.public_subnet_ids[0]
    nat_sg_ids              = [module.security.nat_sg_id]
    private_route_table_ids = module.network.private_route_table_ids

    # GitLab 인스턴스
    gitlab_instance_type = var.gitlab_instance_type
    gitlab_subnet_id     = module.network.public_subnet_ids[0]
    gitlab_sg_ids        = [module.security.ssh_sg_id, module.security.gitlab_sg_id]
}