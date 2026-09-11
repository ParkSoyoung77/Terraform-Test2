resource "aws_instance" "std17_ex_instance" {
    ami     = var.instance_ami
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    key_name = "std17-key"

    root_block_device {
        volume_size = 8
        volume_type = "gp3"
        delete_on_termination = true
        tags = {
            Name = "std17-ex-volume"
        }
    }

    ebs_block_device {
        device_name = "/dev/sdf"
        volume_size = 5
        volume_type = "gp3"
        delete_on_termination = true
        tags = {
            Name = "std17-ex-extra-volume"
        }
    }

    vpc_security_group_ids = [
        var.ssh_sg_id,
        var.external_alb_sg_id
    ]

    user_data                   = templatefile("${path.module}/scripts/user_data.sh.tpl", {
        efs_id = var.efs_id
    })
    user_data_replace_on_change = true
    
    tags = {
        Name = "std17-ex-instance"
    }
}

resource "aws_ami_from_instance" "std17_nginx_ami" {
    name = "std17-ex-nginx-ami"
    source_instance_id = aws_instance.std17_ex_instance.id

    # 재부팅하여 이미지 생성: false
    snapshot_without_reboot = false

    tags = {
        Name = "std17-ex-nginx-ami"
    }
}

# ===============================================
# 키페어
# ===============================================

# resource "aws_key_pair" "std17_lab_key" {
#     key_name = "std17-lab-key"
#     public_key = file("~/.ssh/id_rsa.pub")

#     tags = {
#         Name = "std17-lab-key"
#     }
# }

# =========================================================
# S3 엔드포인트 설정
# =========================================================
# 1. 서비스 데이터 소스 정의 
data "aws_vpc_endpoint_service" "s3" {
    service         = "s3"
    service_type    = "Gateway"
}

# 2. 엔드포인트 생성 및 연결
resource "aws_vpc_endpoint" "s3_endpoint" {
    vpc_id            = var.vpc_id
    service_name      = data.aws_vpc_endpoint_service.s3.service_name

    vpc_endpoint_type = "Gateway"

    route_table_ids   = concat(values(var.private_route_table_ids), [var.cluster_route_table_id])

    tags = { Name = "${local.tag_header}s3-endpoint"}
}

# =========================================================
# ECR 인터페이스 엔드포인트
# =========================================================
resource "aws_vpc_endpoint" "ecr_api" {
    vpc_id  = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.api"
    vpc_endpoint_type = "Interface"

    private_dns_enabled = true

    subnet_ids = concat(var.private_subnet_ids, var.cluster_subnet_ids)

    security_group_ids = [ var.eks_node_sg_id ]

    tags = { Name = "${local.tag_header}ecr-api-vpce"}
}

resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id  = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
    vpc_endpoint_type = "Interface"

    private_dns_enabled = true

    subnet_ids = concat(var.private_subnet_ids, var.cluster_subnet_ids)

    security_group_ids = [ var.eks_node_sg_id ]

    tags = { Name = "${local.tag_header}ecr-dkr-vpce"}
}