module "network" {
    source      = "./modules/network"
    azs         = local.azs
    vpc_cidr    = local.vpc_cidr
    tag_header  = local.tag_header
}

module "storage" {
    source      = "./modules/storage"
}

module "database" {
    source      = "./modules/database"
    private_subnet_ids = module.network.public_subnet_ids
    mysql_sg_id  = module.security.mysql_sg_id
    owner               = var.owner
    vpc_cidr            = var.vpc_cidr
}

module "security" {
    source      = "./modules/security"
    tag_header  = local.tag_header
    vpc_id           = module.network.vpc_id
    public_subnet_ids = module.network.public_subnet_ids
    owner               = var.owner
    vpc_cidr            = var.vpc_cidr
}

module "eks" {
    source      = "./modules/eks"
    tag_header  = local.tag_header
    vpc_id           = module.network.vpc_id
    owner  = var.owner
    private_subnet_ids = module.network.public_subnet_ids
    mysql_sg_id = module.security.mysql_sg_id
    external_alb_sg_id = module.security.external_alb_sg_id
    ssh_sg_id = module.security.ssh_sg_id
    aws_region = var.aws_region
}