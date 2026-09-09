module "network" {
    source      = "./modules/network"
    azs         = local.azs
    vpc_cidr    = local.vpc_cidr
    tag_header  = local.tag_header
}

module "storage" {
    source      = "./modules/storage"
}
