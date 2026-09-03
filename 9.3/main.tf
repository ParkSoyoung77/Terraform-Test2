 module "network" {
    source      = "./modules/network"
    name_prefix = var.name_prefix
    azs         = var.azs
 }