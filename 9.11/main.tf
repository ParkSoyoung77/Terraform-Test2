module "network" {
    source        = "./modules/network"
    azs           = local.azs
    vpc_cidr      = local.vpc_cidr
    tag_header    = local.tag_header
    cluster_name  = "${local.tag_header}eks-cluster"
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
    source              = "./modules/storage"
    vpc_id              = module.network.vpc_id
    tag_header          = local.tag_header
    vpc_cidr            = var.vpc_cidr
    private_subnet_ids  = module.network.private_subnet_ids
}

module "compute" {
    source                  = "./modules/compute"
    vpc_id                  = module.network.vpc_id
    tag_header              = local.tag_header
    subnet_id               = module.network.public_subnet_ids[0]
    private_subnet_ids      = module.network.private_subnet_ids
    cluster_subnet_ids      = module.network.cluster_subnet_ids
    ssh_sg_id               = module.security.ssh_sg_id
    external_alb_sg_id      = module.security.external_alb_sg_id
    eks_node_sg_id          = module.eks.eks_node_sg_id
    private_route_table_ids = module.network.private_route_table_ids
    cluster_route_table_id  = module.network.cluster_route_table_id
    efs_id                  = module.storage.efs_id
}

module "eks" {
    source                  = "./modules/eks"
    tag_header              = local.tag_header
    owner                   = var.owner
    vpc_id                  = module.network.vpc_id
    private_subnet_ids      = module.network.private_subnet_ids
    ssh_sg_id               = module.security.ssh_sg_id
    external_alb_sg_id      = module.security.external_alb_sg_id
    mysql_sg_id             = module.security.mysql_sg_id
    aws_region              = var.aws_region
    principal_arn           = var.principal_arn
}