resource "aws_vpc" "std17_vpc" {
    cidr_block           = var.vpc_cidr
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.name_prefix}-vpc"
    }
}

# ====================================================

resource "aws_subnet" "std17_public_subnet" {
    vpc_id                  = aws_vpc.std17_vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = var.azs[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.name_prefix}-public-subnet"
    }
}

resource "aws_internet_gateway" "std17_igw" {
    vpc_id = aws_vpc.std17_vpc.id

    tags = {
        Name = "${var.name_prefix}-igw"
    }
}

# ====================================================

resource "aws_subnet" "std17_private_subnet" {
    vpc_id            = aws_vpc.std17_vpc.id
    cidr_block        = "10.0.11.0/24"
    availability_zone = var.azs[0]

    tags = {
        Name = "${var.name_prefix}-private-subnet"
    }
}

