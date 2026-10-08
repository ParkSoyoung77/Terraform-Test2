# ====================================================
# 공통 값 — 이름 접두사를 한 곳에서 만들어 모든 모듈에 동일하게 전달
# ====================================================
locals {
    tag_header = var.owner == "" ? "" : "${var.owner}-"
}

# ====================================================
# iam
# ====================================================
module "iam" {
    source = "./modules/iam"

    s3_bucket_name = var.bucket_name

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
module "database" {
    source = "./modules/database"

    private_subnet_ids = module.network.private_subnet_ids   # 수정: public → private
    mysql_sg_id        = module.security.mysql_sg_id
    owner              = var.owner
    vpc_cidr           = var.vpc_cidr
}

# ====================================================
# S3: 정적 웹사이트 버킷 + EC2 백업용 IAM 역할
# ====================================================
module "storage" {
    source = "./modules/storage"
    bucket_name  = var.bucket_name
    api_endpoint = module.apigateway.api_endpoint
}

# ====================================================
# Lambda: DB 연결 확인 함수 (VPC) + S3 버킷 함수
# ====================================================
module "lambda" {
  source         = "./modules/lambda"
  s3_bucket_name = var.bucket_name
}


# ====================================================
# API Gateway: 브라우저 → Lambda 호출 주소
# ====================================================
module "apigateway" {
    source = "./modules/apigateway"

    tag_header = local.tag_header

    routes = {
        delete_bucket = {
            route_key     = "GET /bucket/delete"
            function_name = module.lambda.function_name
            invoke_arn    = module.lambda.invoke_arn
        }
    }
}