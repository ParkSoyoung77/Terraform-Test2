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

    user_data                   = file("${path.module}/scripts/user_data.sh.tpl")
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

resource "aws_launch_template" "asg_lt" {
    name_prefix   = "${local.tag_header}-"
    image_id      = local.ami_id 
    instance_type = var.instance_type
    key_name      = local.key_name
    vpc_security_group_ids = [ var.external_alb_sg_id, var.ssh_sg_id]

    # 기본 버전 지정 방법
    update_default_version = var.default_version == "latest" ? true : false
    default_version         = var.default_version != "latest" ? tostring(var.default_version) : null

    iam_instance_profile {
        name = var.instance_profile_name
    }

    user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    # ruby: CodeDeploy서비스 개발 언어, codedeploy-agent 설치를 위해 반드시 필요
    dnf install -y ruby wget docker

    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    cd /tmp
    wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto

    systemctl start codedeploy-agent
    systemctl enable codedeploy-agent
    EOF
    )

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "${local.tag_header}asg-node-instance"
        }
    }
}

data "aws_subnets" "target_subnets" {
  filter {
    name   = "tag:Type"
    values = [var.subnet_tag_type]
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${local.tag_header}codedeploy-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = data.aws_subnets.target_subnets.ids

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
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

    subnet_ids = var.private_subnet_ids

    security_group_ids = [ var.ecr_endpoint_sg_id ]

    tags = { Name = "${local.tag_header}ecr-api-vpce"}
}

resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id  = var.vpc_id
    service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
    vpc_endpoint_type = "Interface"

    private_dns_enabled = true

    subnet_ids = var.private_subnet_ids

    security_group_ids = [ var.ecr_endpoint_sg_id ]

    tags = { Name = "${local.tag_header}ecr-dkr-vpce"}
}