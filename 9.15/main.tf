module "mumbai_network" {
  source = "./modules/network"
  # providers = { aws = aws.seoul }
  azs                = local.azs
  vpc_cidr_block     = local.vpc_cidr_block
  subnet_map         = local.subnet_map
  route_map          = local.route_map
  subnet_type        = var.subnet_type
  tag_header         = local.tag_header
  create_nat_gateway = var.create_nat_gateway
  ssh_key            = var.ssh_key
  vpc_options        = local.vpc_options
  ami_id             = local.ami_id
  region             = local.region
}

module "rds" {
  source      = "./modules/database"
  tag_header  = local.tag_header
  vpc_id      = local.vpc_id
  region      = local.region
  mysql_sg_id = local.mysql_sg_id
}
