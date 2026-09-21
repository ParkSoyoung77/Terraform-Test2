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

module "compute" {
    source                  = "./modules/compute"
    vpc_id                  = module.network.vpc_id
    tag_header              = local.tag_header
    subnet_id               = module.network.public_subnet_ids[0]

    private_subnet_ids      = module.network.private_subnet_ids
    cluster_subnet_ids      = module.network.cluster_subnet_ids

    ssh_sg_id               = module.security.ssh_sg_id
    external_alb_sg_id      = module.security.external_alb_sg_id
    ecr_endpoint_sg_id      = module.security.ecr_endpoint_sg_id
    
    private_route_table_ids = module.network.private_route_table_ids
    cluster_route_table_id  = module.network.cluster_route_table_id

    subnet_tag_type         = "private"
}

module "storage" {
    source              = "./modules/storage"
    vpc_id              = module.network.vpc_id
    owner               = var.owner
    tag_header          = local.tag_header
    vpc_cidr            = var.vpc_cidr
    private_subnet_ids  = module.network.private_subnet_ids
}

# module "iam" {
#     source              = "./modules/iam"
#     tag_header = local.tag_header
# }


# ====================================================
# CodeDeploy 모듈 - ASG 기반 CodeDeploy 배포 환경
# ====================================================
module "codedeploy" {
    source = "./modules/codedeploy"

    providers = {
        aws       = aws
        aws.tokyo = aws.tokyo
    }

    tag_header             = local.tag_header
    golden_ami_id           = module.compute.golden_ami_id   
    vpc_security_group_ids  = [module.security.external_alb_sg_id, module.security.ssh_sg_id]
    
    subnet_tag_type         = "private"
    
    github_repository_id    = "ParkSoyoung77/Terraform-Test2"
    github_branch           = "main"
}