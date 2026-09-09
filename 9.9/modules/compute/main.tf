resource "aws_instance" "std17_ex_instance" {
    ami     = var.instance_ami
    instance_type = var.instance_type

    subnet_id = var.subnet_ids[0]
    key_name = "std17-key"

    root_block_device {
        volume_size = 20
        volume_type = "gp3"
        delete_on_termination = true # 인스턴스 삭제 시, 볼륨 같이 삭제
        tags = {
            Name = "std17-ex-volume"
        }
    }

    vpc_security_group_ids = [
        var.ssh_sg_id,
        var.external_alb_sg_id
    ]

    user_data                   = file("${path.module}/scripts/user_data.sh")
    user_data_replace_on_change = true
    
    tags = {
        Name = "std17-ex-instance"
    }
}


# ====================================================
# ami
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

# ====================================================
# tg
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

resource "aws_lb_target_group_attachment" "std17_ex_nginx_tg_attachment" {
    target_group_arn = aws_lb_target_group.std17_ex_nginx_tg.arn
    target_id         = aws_instance.std17_ex_instance.id
    port              = 80
}

# ===============================================
# 로드밸런서
# ===============================================
resource "aws_lb" "std17_ex_alb" {
    name = "std17-ex-alb"
    internal = false
    load_balancer_type = "application"
    subnets = var.subnet_ids

    security_groups = [
        var.external_alb_sg_id
    ]


    tags = {Name = "std17-ex-alb"}
}

resource "aws_lb_listener" "std17_ex_lb_http_listner" {
    load_balancer_arn = aws_lb.std17_ex_alb.arn
    protocol          = "HTTP"
    port              = 80 # 사용자의 포트번호(외부/브라우저)

    default_action {
        type             = "forward" # 전달/승계(대상그룹)
        target_group_arn = aws_lb_target_group.std17_ex_nginx_tg.arn
    }

}


# Listner에 경로 규칙추가
resource  "aws_lb_listener_rule" "std17_ex_lb_http_listener_path_rule" {
    listener_arn    = aws_lb_listener.std17_ex_lb_http_listner.arn

    # 1~50,000 사이의 규칙우선순위 지정, 낮을 수록 우선 순위가 높음.
    priority    = 100
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.std17_ex_nginx_tg.arn
    }
    
    # [라우팅 조건] URL 경로 정의
    condition {
        path_pattern {
            values = ["/api", "api/*"]
        }
    } 

    tags = { Name = "std17-ex-lb-http-listener-path-rule"}
}