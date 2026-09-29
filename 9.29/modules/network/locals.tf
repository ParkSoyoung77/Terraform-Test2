locals {
  azs         = data.aws_availability_zones.available_az.names
  vpc_cidr    = var.vpc_cidr
  tag_header  = var.tag_header
  cidr_header = "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}"

  subnet_map = merge([
    for idx, key in ["public", "private"] : {
      for i, az in local.azs : "${key}${split("-", az)[2]}" => {
        type = key
        az   = az
        cidr = "${local.cidr_header}.${i + (idx * 10 + 1)}.0/24"
      }
    }
  ]...)

  public_subnets  = { for k, v in local.subnet_map : k => v if v.type == "public" }
  private_subnets = { for k, v in local.subnet_map : k => v if v.type == "private" }
}