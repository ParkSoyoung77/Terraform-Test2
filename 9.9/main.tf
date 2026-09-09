module "network" {
    source      = "./modules/network"
    name_prefix = var.name_prefix
    azs         = var.azs
}

module "security" {
    source      = "./modules/security"
    name_prefix = var.name_prefix
    vpc_id           = module.network.vpc_id
    public_subnet_ids = module.network.public_subnet_ids
}

module "compute" {
    source      = "./modules/compute"
    name_prefix = var.name_prefix
    public_subnet_ids = module.network.public_subnet_ids
    ssh_sg_id           = module.security.ssh_sg_id
    external_alb_sg_id  = module.security.external_alb_sg_id
    vpc_id = module.network.vpc_id
}

module "storage" {
    source      = "./modules/storage"
}

module "database" {
    source      = "./modules/database"
    name_prefix = var.name_prefix
    private_subnet_ids = module.network.public_subnet_ids
    mysql_sg_id  = module.security.mysql_sg_id
    lambda_sg_id = module.security.lambda_sg_id
}
