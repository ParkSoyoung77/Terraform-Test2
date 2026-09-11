# =========================================================
# S3 엔드포인트 설정
# =========================================================
# 1. 서비스 데이터 소스 정의 
data "aws_vpc_endpoint_service" "s3" {
    service         = "s3"
    service_type    = "Gateway"
}

# 2. 엔드포인트 생성 및 연결
resource "aws_vpc_endpoint" "s3_endpoint" {
    vpc_id            = var.vpc_id
    service_name      = data.aws_vpc_endpoint_service.s3.service_name

    vpc_endpoint_type = "Gateway"

    route_table_ids   = [var.private_route_table_id]

    tags = { Name = "${local.tag_header}s3-endpoint"}
}

# =========================================================
# ECR 인터페이스 엔드포인트
# =========================================================
resource "aws_vpc_endpoint" "ecr_api" {
    vpc_id  = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.api"
    vpc_endpoint_type = "Interface"

    # [필수] ECR의 기본 URL 주소 호환
    private_dns_enabled = true

    subnet_ids = var.private_subnet_ids

    # ECR은 통신포트로 433 사용
    security_group_ids = [ var.external_alb_sg_id ]

    tags = { Name = "${local.tag_header}ecr-api-vpce"}
}

resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id  = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
    vpc_endpoint_type = "Interface"

    # [필수] ECR의 기본 URL 주소 호환
    private_dns_enabled = true

    subnet_ids = var.private_subnet_ids

    # ECR은 통신포트로 433 사용
    security_group_ids = [ var.external_alb_sg_id ]

    tags = { Name = "${local.tag_header}ecr-dkr-vpce"}    
}