# ==================================================================
# 가용영역 / 서브넷 계산
# ==================================================================
data "aws_availability_zones" "available_az" {
    state = "available"

    # Local Zone / Wavelength 제외, 일반 AZ만
    filter {
        name   = "opt-in-status"
        values = ["opt-in-not-required"]
    }
}

data "aws_region" "current" {}

# ==================================================================
# VPC
# ==================================================================
resource "aws_vpc" "std17_vpc" {
    cidr_block           = local.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = {
        Name = "${local.tag_header}-vpc"
    }
}

resource "aws_default_route_table" "std17_vpc_default_rt" {
    default_route_table_id = aws_vpc.std17_vpc.default_route_table_id
    tags = {
        Name = "${local.tag_header}-vpc-default-rt"
    }
}

# ==================================================================
# public subnets
# ==================================================================
resource "aws_subnet" "std17_public_subnets" {
    for_each = local.public_subnets

    vpc_id                                      = aws_vpc.std17_vpc.id
    cidr_block                                  = each.value.cidr
    availability_zone                           = each.value.az
    map_public_ip_on_launch                     = true
    enable_resource_name_dns_a_record_on_launch = true
    private_dns_hostname_type_on_launch         = "ip-name"
    tags = {
        Name = "${local.tag_header}-${each.key}-subnet"
    }
}

# IGW
resource "aws_internet_gateway" "std17_vpc_igw" {
    vpc_id = aws_vpc.std17_vpc.id
    tags = {
        Name = "${local.tag_header}-vpc-igw"
    }
}

# public rt
resource "aws_route_table" "std17_vpc_public_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.std17_vpc_igw.id
    }

    tags = {
        Name = "${local.tag_header}-vpc-public-rt"
    }
}

resource "aws_route_table_association" "std17_vpc_public_rt_assoc" {
    for_each = aws_subnet.std17_public_subnets

    route_table_id = aws_route_table.std17_vpc_public_rt.id
    subnet_id      = each.value.id
}

# ==================================================================
# private subnets (ASG / RDS)
# ==================================================================
resource "aws_subnet" "std17_private_subnets" {
    for_each = local.private_subnets

    vpc_id            = aws_vpc.std17_vpc.id
    cidr_block        = each.value.cidr
    availability_zone = each.value.az
    tags = {
        Name = "${local.tag_header}-${each.key}-subnet"
    }
}

# 프라이빗 라우팅 테이블
# 0.0.0.0/0 -> NAT 인스턴스 경로는 nat-instance 모듈의 aws_route 로 추가
resource "aws_route_table" "std17_vpc_private_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    tags = {
        Name = "${local.tag_header}-vpc-private-rt"
    }
}

resource "aws_route_table_association" "std17_vpc_private_rt_assoc" {
    for_each = aws_subnet.std17_private_subnets

    route_table_id = aws_route_table.std17_vpc_private_rt.id
    subnet_id      = each.value.id
}

# ==================================================================
# eks 전용 private subnets
# ==================================================================
# resource "aws_subnet" "std17_eks_private_subnets" {
#     for_each = local.eks_subnets

#     vpc_id            = aws_vpc.std17_vpc.id
#     cidr_block        = each.value.cidr
#     availability_zone = each.value.az
#     tags = {
#         Name                              = "${local.tag_header}-${each.key}-subnet"
#         "kubernetes.io/role/internal-elb" = "1"
#     }
# }

# # eks 전용 라우팅 테이블
# # 0.0.0.0/0 -> NAT 인스턴스 경로는 nat-instance 모듈의 aws_route 로 추가
# resource "aws_route_table" "std17_vpc_eks_private_rt" {
#     vpc_id = aws_vpc.std17_vpc.id

#     tags = {
#         Name = "${local.tag_header}-vpc-eks-private-rt"
#     }
# }

# resource "aws_route_table_association" "std17_vpc_eks_private_rt_assoc" {
#     for_each = aws_subnet.std17_eks_private_subnets

#     route_table_id = aws_route_table.std17_vpc_eks_private_rt.id
#     subnet_id      = each.value.id
# }

# ==================================================================
# S3 Gateway Endpoint
# ==================================================================
resource "aws_vpc_endpoint" "std17_s3_gateway" {
    vpc_id            = aws_vpc.std17_vpc.id
    service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
    vpc_endpoint_type = "Gateway"

    route_table_ids = [
        aws_route_table.std17_vpc_private_rt.id,
        # aws_route_table.std17_vpc_eks_private_rt.id,
    ]

    tags = {
        Name = "${local.tag_header}-s3-gateway-endpoint"
    }
}