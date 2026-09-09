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
