locals {
  azs         = data.aws_availability_zones.available_az.names
  owner       = var.owner
  vpc_cidr    = var.vpc_cidr
  name_prefix = var.owner == "" ? "" : "${var.owner}-"
}