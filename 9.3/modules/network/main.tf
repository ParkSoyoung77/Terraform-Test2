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

    count = 3

    vpc_id                  = aws_vpc.std17_vpc.id
    cidr_block              = "10.0.${count.index + 1}.0/24"
    availability_zone       = var.azs[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.name_prefix}-public${count.index + 1}-subnet"
    }
}

resource "aws_internet_gateway" "std17_igw" {
    vpc_id = aws_vpc.std17_vpc.id

    tags = {
        Name = "${var.name_prefix}-igw"
    }
}

resource "aws_route_table" "std17_public_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    tags = {
        Name = "${var.name_prefix}-public-rt"
    }
}

resource "aws_route" "std17_public_rt_route" {
    route_table_id         = aws_route_table.std17_public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id              = aws_internet_gateway.std17_igw.id
}

resource "aws_route_table_association" "std17_public_rt_assoc" {
    count          = 3
    subnet_id      = aws_subnet.std17_public_subnet[count.index].id
    route_table_id = aws_route_table.std17_public_rt.id
}

# ====================================================

resource "aws_subnet" "std17_private_subnet" {
    count             = 3
    vpc_id            = aws_vpc.std17_vpc.id
    cidr_block        = "10.0.${count.index + 11}.0/24"
    availability_zone = var.azs[count.index]

    tags = {
        Name = "${var.name_prefix}-private${count.index + 1}-subnet"
    }
}

resource "aws_eip" "std17_nat_eip" {
    domain = "vpc"

    tags = {
        Name = "${var.name_prefix}-nat-eip"
    }
}

resource "aws_nat_gateway" "std17_nat_gw" {
    allocation_id = aws_eip.std17_nat_eip.id
    subnet_id     = aws_subnet.std17_public_subnet[0].id

    depends_on = [
        aws_internet_gateway.std17_igw
    ]

    tags = {
        Name = "${var.name_prefix}-nat-gw"
    }
}

resource "aws_route_table" "std17_private_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    tags = {
        Name = "${var.name_prefix}-private-rt"
    }
}

resource "aws_route" "std17_private_rt_route" {
    route_table_id         = aws_route_table.std17_private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id              = aws_nat_gateway.std17_nat_gw.id
}

resource "aws_route_table_association" "std17_private_rt_assoc" {
    count          = 3
    subnet_id      = aws_subnet.std17_private_subnet[count.index].id
    route_table_id = aws_route_table.std17_private_rt.id
}