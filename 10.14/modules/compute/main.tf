# ==================================================================
# Amazon Linux 2023 최신 AMI (x86_64, minimal 제외)
data "aws_ami" "std17_al2023" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-2023.*-kernel-*-x86_64"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# ==================================================================
# 시작 템플릿: AL2023 / t3.micro / 루트 10GB / user_data(Docker + nginx)
resource "aws_launch_template" "std17_nginx" {
    name_prefix   = "${var.name_prefix}-nginx-lt-"
    image_id      = data.aws_ami.std17_al2023.id
    instance_type = var.instance_type
    key_name      = var.key_name

    iam_instance_profile {
        name = var.instance_profile_name
    }

    vpc_security_group_ids = [var.security_group_id]

    # AL2023 기본 루트 볼륨은 10GB로 지정
    block_device_mappings {
        device_name = data.aws_ami.std17_al2023.root_device_name
        ebs {
            volume_size           = var.root_volume_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
        }
    }

    # IMDSv2 강제 (user_data에서 토큰 방식으로 메타데이터 조회)
    metadata_options {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
    }

    user_data = filebase64("${path.module}/scripts/user_data.sh")

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "${var.name_prefix}-nginx-ec2"
        }
    }

    tag_specifications {
        resource_type = "volume"
        tags = {
            Name = "${var.name_prefix}-nginx-ec2-root"
        }
    }

    tags = {
        Name = "${var.name_prefix}-nginx-lt"
    }
}

# ==================================================================
# ASG: 프라이빗 서브넷 3개, ALB 타겟그룹 연결
resource "aws_autoscaling_group" "std17_nginx_asg" {
    name                      = "${var.name_prefix}-nginx-asg"
    min_size                  = var.asg_min_size
    desired_capacity          = var.asg_desired_capacity
    max_size                  = var.asg_max_size
    vpc_zone_identifier       = var.subnet_ids
    target_group_arns         = [var.alb_target_group_arn]
    health_check_type         = "ELB"
    health_check_grace_period = 300 # docker 설치 + 이미지 pull 시간 확보

    launch_template {
        id      = aws_launch_template.std17_nginx.id
        version = aws_launch_template.std17_nginx.latest_version
    }

    # 시작 템플릿(user_data 등)이 바뀌면 인스턴스를 순차 교체
    instance_refresh {
        strategy = "Rolling"
        preferences {
            min_healthy_percentage = 50
        }
    }

    tag {
        key                 = "Name"
        value               = "${var.name_prefix}-nginx-ec2"
        propagate_at_launch = true
    }
}
