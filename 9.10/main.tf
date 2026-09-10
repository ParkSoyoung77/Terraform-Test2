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
    lambda_sg_id = module.lambda.security_group_id
}