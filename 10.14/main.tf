# ==================================================================
# 요구사항
#   1) Nginx Container - ASG/ALB - Amazon Linux(t3.micro, 10GB), Docker
#   2) RDB - MySQL, Instance  (RDS MySQL 단일 DB 인스턴스)
#   3) EKS
# ==================================================================

# ==================================================================
# 1-1. 네트워크 (VPC, public 3 / private 3 / eks전용 private 3, NAT 1)
# ==================================================================
module "network" {
    source      = "./modules/network"
    name_prefix = var.name_prefix
    vpc_cidr    = var.vpc_cidr
    az_count    = var.az_count
}

# ==================================================================
# 1-2. NAT 인스턴스 (NAT 게이트웨이 대체)
#      private / eks 라우팅 테이블에 0.0.0.0/0 -> NAT 인스턴스 경로 추가
# ==================================================================
module "nat_instance" {
    source                  = "./modules/nat-instance"
    name_prefix             = var.name_prefix
    key_name                = var.key_name
    instance_profile_name   = module.iam.ec2_instance_profile_name
    nat_subnet_id           = module.network.nat_subnet_id
    nat_sg_ids              = [module.security.nat_sg_id]
    private_route_table_ids = module.network.private_route_table_ids
}

# ==================================================================
# 2. 보안그룹 (ALB -> EC2 -> RDS)
# ==================================================================
module "security" {
    source      = "./modules/security"
    name_prefix = var.name_prefix
    vpc_id      = module.network.vpc_id
    vpc_cidr    = module.network.vpc_cidr

    # 내 PC -> NAT 인스턴스 SSH 허용 IP
    ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

# ==================================================================
# 3. IAM (EC2 인스턴스 프로파일: SSM 접속 + ECR pull)
# ==================================================================
module "iam" {
    source      = "./modules/iam"
    name_prefix = var.name_prefix
}

# ==================================================================
# 4. ALB (퍼블릭 서브넷, HTTP 80 -> nginx 타겟그룹)
# ==================================================================
module "alb" {
    source            = "./modules/alb"
    name_prefix       = var.name_prefix
    vpc_id            = module.network.vpc_id
    public_subnet_ids = module.network.public_subnet_ids
    security_group_id = module.security.alb_sg_id
}

# ==================================================================
# 5. Compute: ASG + Launch Template
#    Amazon Linux 2023 / t3.micro / 루트 10GB / Docker로 nginx 컨테이너 실행
# ==================================================================
module "compute" {
    source                = "./modules/compute"
    name_prefix           = var.name_prefix
    subnet_ids            = module.network.private_subnet_ids
    security_group_id     = module.security.ec2_sg_id
    instance_profile_name = module.iam.ec2_instance_profile_name
    key_name              = var.key_name
    alb_target_group_arn  = module.alb.target_group_arn

    # NAT 경로가 준비된 뒤 인스턴스가 떠야 docker 설치/이미지 pull 이 성공함
    depends_on = [module.nat_instance, module.network]
}

# ==================================================================
# 6. RDS MySQL (단일 DB 인스턴스, 프라이빗 서브넷)
# ==================================================================
module "rds" {
    source             = "./modules/rds"
    name_prefix        = var.name_prefix
    private_subnet_ids = module.network.private_subnet_ids
    security_group_id  = module.security.rds_sg_id
}

# ==================================================================
# 7. EKS (클러스터 + 관리형 노드그룹, EKS 전용 프라이빗 서브넷)
# ==================================================================
module "eks" {
    source             = "./modules/eks"
    name_prefix        = var.name_prefix
    private_subnet_ids = module.network.eks_private_subnet_ids
    cluster_name       = "${var.name_prefix}-eks-cluster"
    node_group_name    = "${var.name_prefix}-eks-nodegroup"

    # 노드 SSH: NAT 인스턴스(점프 호스트)에서만 22 허용
    node_ssh_key_name      = var.key_name
    node_ssh_source_sg_ids = [module.security.nat_sg_id]

    # 노드가 클러스터에 조인하려면 외부(ECR 등) 통신 경로가 먼저 있어야 함
    depends_on = [module.nat_instance, module.network]
}

# ==================================================================
# 8. 루트 레벨 보안그룹 규칙 (모듈 간 순환참조 회피)
# ==================================================================
# EKS 관리형 노드에는 클러스터 기본 SG가 붙으므로 그 SG를 소스로 허용
resource "aws_security_group_rule" "rds_from_eks_node" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_group_id        = module.security.rds_sg_id
    source_security_group_id = module.eks.cluster_primary_security_group_id
    description              = "eks node to RDS"
}

# ==================================================================
# 9. CloudWatch 대시보드 (Nginx ASG + EKS 노드 ASG)
# ==================================================================
module "cloudwatch" {
    source         = "./modules/cloudwatch"
    dashboard_name = "instance-board"

    asg_names    = [
        module.compute.asg_name,
        module.eks.node_asg_name,
    ]
}