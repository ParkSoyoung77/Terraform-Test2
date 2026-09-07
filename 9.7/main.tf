module "network" {
    source      = "./modules/network"
    name_prefix = var.name_prefix
    azs         = var.azs
 }

module "security" {
    source      = "./modules/security"
    name_prefix = var.name_prefix
    vpc_id           = module.network.vpc_id
    public_subnet_id = module.network.public_subnet_id
 }

module "compute" {
    source      = "./modules/compute"
    name_prefix = var.name_prefix
    public_subnet_id = module.network.public_subnet_id
    ssh_sg_id           = module.security.ssh_sg_id
    external_alb_sg_id  = module.security.external_alb_sg_id
 }

module "storage" {
    source      = "./modules/storage"
 }