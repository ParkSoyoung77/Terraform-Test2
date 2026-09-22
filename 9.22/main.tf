module "network" {
    source = "./network"

    owner    = var.owner
    vpc_cidr = var.vpc_cidr
}

module "security" {
    source = "./security"

    vpc_id     = module.network.vpc_id
    vpc_cidr   = var.vpc_cidr
    tag_header = var.tag_header
}

module "compute" {
    source = "./compute"

    aws_region               = var.aws_region
    tag_header               = var.tag_header
    vpc_id                   = module.network.vpc_id
    subnet_id                = module.network.public_subnet_ids[0]
    private_subnet_ids       = module.network.private_subnet_ids
    private_route_table_ids  = module.network.private_route_table_ids
    ssh_sg_id                = module.security.ssh_sg_id
    external_alb_sg_id       = module.security.external_alb_sg_id
    gitlab_sg_id             = module.security.gitlab_sg_id
}