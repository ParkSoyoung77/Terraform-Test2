locals {
  azs         = data.aws_availability_zones.available_az.names
  owner       = var.owner
  vpc_cidr    = var.vpc_cidr
  tag_header  = var.owner == "" ? "" : "${var.owner}-"
  cidr_header = "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}"

  subnet_map = merge([
    for idx, key in ["public", "private", "cluster"] : {
      for i, az in local.azs : "${key}${split("-", az)[2]}" => {
        type = key
        az   = az
        cidr = "${local.cidr_header}.${i + (idx * 10 + 1)}.0/24"
      }
    }
  ]...)
}