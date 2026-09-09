# ====================================================
# lab용 vpc 생성
# ====================================================
resource "aws_vpc" "this" {
    cidr_block           = local.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags = {
        Name = "${local.tag_header}-vpc"
    }
}

resource "aws_subnet" "this"{
    for_each = local.subnet_map

    vpc_id            = aws_vpc.this.id
    availability_zone = each.value.az
    cidr_block        = each.value.cidr

    map_public_ip_on_launch = each.value.type == "public" ? true :false

    enable_resource_name_dns_a_record_on_launch = true

    tags = merge({
        "Name"        = "${local.tag_header}${each.key}-subnet"
        "Type"        = each.value.type
        "Environment" = "test"
        "ManagedBy"   =  "Terraform"
    })
}