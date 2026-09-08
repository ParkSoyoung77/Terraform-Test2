# resource "aws_instance" "std17_ex_instance" {
#     ami     = var.instance_ami
#     instance_type = var.instance_type

#     subnet_id = var.subnet_ids[0]
#     key_name = "std17-key"

#     root_block_device {
#         volume_size = 20
#         volume_type = "gp3"
#         delete_on_termination = true # 인스턴스 삭제 시, 볼륨 같이 삭제
#         tags = {
#             Name = "std17-ex-volume"
#         }
#     }

#     vpc_security_group_ids = [
#         var.ssh_sg_id,
#         var.external_alb_sg_id
#     ]

#     user_data                   = file("${path.module}/scripts/user_data.sh")
#     user_data_replace_on_change = true
    
#     tags = {
#         Name = "std17-ex-instance"
#     }
# }


# ====================================================
# ami, lt
# ====================================================
resource "aws_ami_from_instance" "std17_nginx_ami" {
    name = "std17-ex-nginx-ami"
    source_instance_id = aws_instance.std17_ex_instance.id

    # 재부팅하여 이미지 생성: false
    snapshot_without_reboot = false

    tags = {
        Name = "std17-ex-nginx-ami"
    }
}


resource "aws_launch_template" "std17_ex_lt" {
    name_prefix = "std17-ex-lt-"
    image_id    = aws_ami_from_instance.std17_nginx_ami.id
    instance_type = "t3.nano"

    vpc_security_group_ids = [
        var.ssh_sg_id,
        var.external_alb_sg_id
    ]

    # 시작 템플릿에서는 base64encode)를 통해 암호화 필요
    user_data = base64encode(<<-EOF
    #!/bin/bash
    systemctl start nginx
    systemctl enable nginx
    EOF
    )

    tag_specifications {
        resource_type = "instance"
        tags = { Name = "std17-ex-asg-instance"}
    }

    tag_specifications {
        resource_type = "volume"
        tags = { Name = "std17-ex-asg-instance-vol"}
    }

    tags = { Name = "std17-ex-asg-lt"}
}

# ====================================================
# tg, asg
# ====================================================
resource "aws_lb_target_group" "std17_ex_nginx_tg" {
    name = "std17-ex-nginx-tg"
    vpc_id   = var.vpc_id

    protocol = "HTTP"
    port     = 80
    
    # 인스턴 스 연결 대기 시간 정의
    slow_start           = 30

    # 인스턴스 종료 시 연결 유지 시간
    deregistration_delay = 60

    # 헬스 체크
    health_check {
        protocol = "HTTP"
        path     = "/"
        port     = "traffic-port" # 기본값으로 위 서비스 포트번호를 따라감

        interval = 15   # 15초마다 한 번씩 검사
        timeout  = 5    # 응답을 기다리는 시간

        # 최종 성공/실패의 인정기준(횟수)
        healthy_threshold = 3    # 3번 연속 성공하면 '정상'
        unhealthy_threshold = 3 # 3번 연속 실패하면 '실패'
    }

    tags = { Name = "std17-ex-nginx-tg"}
}

resource "aws_autoscaling_group" "std17_ex_nginx_asg"{
    name = "std17-nginx-tg"
    min_size         = 1
    max_size         = 2
    desired_capacity = 2

    # 네트워크
    vpc_zone_identifier = var.subnet_ids

    # 대상그룹(ARN)
    target_group_arns = [
        aws_lb_target_group.std17_ex_nginx_tg.arn
    ]

    launch_template {
        id = aws_launch_template.std17_ex_lt.id
        version = "$Latest"
    }

    # 헬스 체크
    health_check_type         = "EC2"   # or ELB
    health_check_grace_period = 300     # 인스턴스 기동 후 헬스체크 유예시간(초)

    tag {
        key                 = "Name"
        value               = "std17-ex-nginx-asg"
        propagate_at_launch = false # EC2 인스턴스에도 동일한 태그를 적용했는지
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