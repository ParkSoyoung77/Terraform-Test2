# ====================================================
# lab용 vpc 생성
# ====================================================
resource "aws_vpc" "this" {
    cidr_block           = local.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags = {
        Name = "${local.tag_header}vpc"
    }
}

resource "aws_subnet" "this" {
    for_each = local.subnet_map

    vpc_id            = aws_vpc.this.id
    availability_zone = each.value.az
    cidr_block        = each.value.cidr

    map_public_ip_on_launch = each.value.type == "public"

    enable_resource_name_dns_a_record_on_launch = true

    tags = {
        Name = "${local.tag_header}${each.key}-subnet"
        Type = each.value.type
    }
}

# ====================================================
# Internet Gateway
# ====================================================
resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id

    tags = {
        Name = "${local.tag_header}igw"
    }
}

# ====================================================
# public 라우팅
# ====================================================
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id

    tags = {
        Name = "${local.tag_header}public-rt"
    }
}

resource "aws_route" "public" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
    for_each = local.public_subnets

    subnet_id      = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.public.id
}

# ====================================================
# private 라우팅
# ※ 0.0.0.0/0 → NAT 인스턴스 경로는 compute 모듈에서 추가 (NAT 인스턴스가 compute 모듈에 있음)
# ====================================================
resource "aws_route_table" "private" {
    for_each = local.private_subnets

    vpc_id = aws_vpc.this.id

    tags = {
        Name = "${local.tag_header}${each.key}-rt"
    }
}

resource "aws_route_table_association" "private" {
    for_each = local.private_subnets

    subnet_id      = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.private[each.key].id
}

# ====================================================
# S3 게이트웨이 엔드포인트 (프라이빗 서브넷 → S3 트래픽은 NAT를 거치지 않음)
# ====================================================
data "aws_vpc_endpoint_service" "s3" {
    service      = "s3"
    service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id            = aws_vpc.this.id
    service_name      = data.aws_vpc_endpoint_service.s3.service_name
    vpc_endpoint_type = "Gateway"
    route_table_ids   = [for rt in aws_route_table.private : rt.id]

    tags = {
        Name = "${local.tag_header}s3-endpoint"
    }
}