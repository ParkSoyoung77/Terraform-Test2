# ====================================================
# 공통 값 — 이름 접두사를 한 곳에서 만들어 모든 모듈에 동일하게 전달
# ====================================================
locals {
    tag_header = var.owner == "" ? "" : "${var.owner}-"
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
}

# ====================================================
# 보안 그룹: NAT / GitLab / SSH / ALB / MySQL / Lambda
# ====================================================
module "security" {
    source = "./modules/security"

    tag_header = local.tag_header
    vpc_id     = module.network.vpc_id
    vpc_cidr   = var.vpc_cidr
}

# ====================================================
# RDS (MySQL 단일 AZ + RDS Proxy) — 프라이빗 서브넷에 배치
# ====================================================
# module "database" {
#     source = "./modules/database"

#     private_subnet_ids = module.network.private_subnet_ids   # 수정: public → private
#     mysql_sg_id        = module.security.mysql_sg_id
#     owner              = var.owner
#     vpc_cidr           = var.vpc_cidr
# }

# ====================================================
# S3: 정적 웹사이트 버킷 + EC2 백업용 IAM 역할
# ====================================================
module "storage" {
    source = "./modules/storage"
}

# ====================================================
# Lambda: DB 연결 확인 함수 (VPC) + S3 버킷 함수
# ====================================================
module "lambda" {
    source = "./modules/lambda"

    # # DB 확인 함수
    # private_subnet_ids = module.network.private_subnet_ids
    # security_group_id  = module.security.lambda_sg_id
    # db_secret_arn      = module.database.db_secret_arn
    # db_host            = module.database.proxy_endpoint
    # db_name            = module.database.db_name

    # S3 버킷 함수
    s3_bucket_name = module.storage.bucket_name
}