resource "aws_lb" "std17_alb" {
    name               = "${var.name_prefix}-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.security_group_id]
    subnets            = var.public_subnet_ids

    tags = {
        Name = "${var.name_prefix}-alb"
    }
}

# nginx 컨테이너가 떠 있는 EC2(호스트 80 -> 컨테이너 80)
resource "aws_lb_target_group" "std17_nginx_tg" {
    name                 = "${var.name_prefix}-nginx-tg"
    port                 = 80
    protocol             = "HTTP"
    vpc_id               = var.vpc_id
    target_type          = "instance"
    deregistration_delay = 30

    health_check {
        path                = "/"
        matcher             = "200"
        healthy_threshold   = 2
        unhealthy_threshold = 5
        interval            = 30
        timeout             = 5
    }

    tags = {
        Name = "${var.name_prefix}-nginx-tg"
    }
}

resource "aws_lb_listener" "std17_http" {
    load_balancer_arn = aws_lb.std17_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.std17_nginx_tg.arn
    }
}
