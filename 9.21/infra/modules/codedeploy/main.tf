# ==========================================
# 1. IAM Roles & Instance Profile
# ==========================================

# (1) EC2 Instance Role (ASG Nodes)
resource "aws_iam_role" "asg_node_role" {
  name = "${var.tag_header}AmazonASGNodeEC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "asg_node_profile" {
  name = "${var.tag_header}ASG-Node-EC2-Instance-Profile"
  role = aws_iam_role.asg_node_role.name
}

# ================================================================================
# CodeDeploy 역할(Role)
# --------------------------------------------------------------------------------
# 역할 생성
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.tag_header}AmazonCodeDeployService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole" # IAM Role을 임시로 획득하여 권한을 행사할 수 있도록 허용
    }]
  })
}

# 관리형 정책을 역할에 연결
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ==========================================
# 2. Launch Template & UserData
# ==========================================

resource "aws_launch_template" "asg_lt" {
  name_prefix            = "${var.tag_header}asg-launch-template-"
  image_id               = var.golden_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  # 기본 버전 지정 방법
  update_default_version = var.default_version == "latest" ? true : false
  default_version         = var.default_version != "latest" ? tostring(var.default_version) : null

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_node_profile.name
  }

  # Docker 및 CodeDeploy Agent 자동 설치 스크립트 (base64 자동 인코딩)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              # ruby: CodeDeploy서비스 개발 언어, codedeploy-agent 설치를 위해 반드시 필요
              dnf install -y ruby wget docker

              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              cd /tmp
              wget https://aws-codedeploy-${var.codedeploy_agent_region}.s3.${var.codedeploy_agent_region}.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto

              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.tag_header}asg-node-instance"
    }
  }
}

# ==========================================
# 3. Auto Scaling Group
# ==========================================

# 타겟 서브넷 조회 (Type 태그 기준)
# data "aws_subnets" "target_subnets" {
#   filter {
#     name   = "tag:Type"
#     values = [var.subnet_tag_type]
#   }
# }

resource "aws_autoscaling_group" "asg" {
  name                = "${var.tag_header}codedeploy-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }
}

# ==========================================
# 4. CodeDeploy Application & Deployment Group
# ==========================================

# CodeDeploy Application 생성
resource "aws_codedeploy_app" "app" {
  compute_platform = "Server"
  name             = "${var.tag_header}asg-codedeploy-app"
}

# CodeDeploy Deployment Group 생성 (ASG 연동)
resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${var.tag_header}asg-deployment-group"

  # codedeploy 서비스에 추가해줄 역할(Role)
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  # 배포 대상정의
  autoscaling_groups    = [aws_autoscaling_group.asg.name]

  # 배포 전략(구성) 지정
  # "CodeDeployDefault.AllAtOnce": 타겟 인스턴스전체에 동시 한 번 배포하는 방식
  #                                (전체 중단 --> 동시 배포 --> 동시 재시작)
  # "OneAtATime": 한 대씩 순차 배포(1대 배포 --> 검증및 다음 배포 대상 선정 --> 순차 반복)
  # "HalfAtATime": 대상 인스턴스의 50%를 먼저 배포 후 나머지 배포
  deployment_config_name = var.deployment_config_name
}