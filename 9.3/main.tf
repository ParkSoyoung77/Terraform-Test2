 module "network" {
    source      = "./modules/network"
    name_prefix = var.name_prefix
    azs         = var.azs
 }

module "security" {
    source      = "./modules/security"
    name_prefix = var.name_prefix
    vpc_id = module.network.vpc_id
 }

 module "compute" {
    source      = "./modules/compute"
    name_prefix = var.name_prefix
    public_subnet_ids = module.network.public_subnet_ids
 }