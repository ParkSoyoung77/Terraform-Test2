module "network" {
    source      = "./modules/network"
    azs         = local.azs
    vpc_cidr    = local.vpc_cidr
    tag_header  = local.tag_header
}

module "security" {
    source      = "./modules/security"
    tag_header  = local.tag_header
    vpc_id           = module.network.vpc_id
    public_subnet_ids = module.network.public_subnet_ids
    owner               = var.owner
    vpc_cidr            = var.vpc_cidr
}

module "storage" {
    source      = "./modules/storage"
    vpc_id                  = module.network.vpc_id
    tag_header              = local.tag_header
}

module "compute" {
    source      = "./modules/compute"
    vpc_id                  = module.network.vpc_id
    tag_header              = local.tag_header
    private_subnet_ids      = module.network.private_subnet_ids
    external_alb_sg_id      = module.security.external_alb_sg_id
    private_route_table_id  = module.network.private_route_table_id
}