# ====================================================
# lab용 vpc 생성
# ====================================================
resource "aws_vpc" "this" {
    cidr_block           = local.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags = {
        Name = "std17-vpc"
    }
}

resource "aws_subnet" "this"{
    for_each = local.subnet_map

    vpc_id            = aws_vpc.this.id
    availability_zone = each.value.az
    cidr_block        = each.value.cidr

    map_public_ip_on_launch = each.value.type == "public" ? true :false

    enable_resource_name_dns_a_record_on_launch = true

    tags = merge(
        {
            "Name" = "${local.tag_header}${each.key}-subnet"
            "Type" = each.value.type
        },
        each.value.type == "public" ? {
            "kubernetes.io/role/elb"                    = "1"
            "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        } : {},
        each.value.type == "cluster" ? {
            "kubernetes.io/role/internal-elb"           = "1"
            "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        } : {}
    )
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
    gateway_id              = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
    for_each = { for k, v in local.subnet_map : k => v if v.type == "public" }

    subnet_id      = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.public.id
}

# ====================================================
# NAT Gateway
# ====================================================
resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name = "${local.tag_header}nat-eip"
    }
}

resource "aws_nat_gateway" "this" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.this[[for k, v in local.subnet_map : k if v.type == "public"][0]].id

    depends_on = [
        aws_internet_gateway.this
    ]

    tags = {
        Name = "${local.tag_header}nat-gw"
    }
}

# ====================================================
# private 라우팅
# ====================================================
locals {
  private_subnets = { for k, v in local.subnet_map : k => v if v.type == "private" }
}

resource "aws_route_table" "private" {
    for_each = local.private_subnets

    vpc_id = aws_vpc.this.id

    tags = {
        Name = "${local.tag_header}${each.key}-rt"
    }
}

resource "aws_route" "private" {
    for_each = local.private_subnets

    route_table_id         = aws_route_table.private[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id          = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
    for_each = local.private_subnets

    subnet_id      = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.private[each.key].id
}

# ====================================================
# cluster 라우팅
# ====================================================
resource "aws_route_table" "cluster" {
    vpc_id = aws_vpc.this.id

    tags = {
        Name = "${local.tag_header}cluster-rt"
    }
}

resource "aws_route" "cluster" {
    route_table_id         = aws_route_table.cluster.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id          = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "cluster" {
    for_each = { for k, v in local.subnet_map : k => v if v.type == "cluster" }

    subnet_id      = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.cluster.id
}