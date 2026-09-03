# SSH용
resource "aws_security_group" "std17_ssh_sg" {
    name = "${var.name_prefix}ssh-sg"
    description = "Security group for SSH access"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}ssh-sg"
    }
}

# MySQL용
resource "aws_security_group" "std17_mysql_sg" {
    name = "${var.name_prefix}mysql-sg"
    description = "Security group for MySQL access"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}mysql-sg"
    }
}

# ALB용
resource "aws_security_group" "std17_external_alb_sg" {
    name = "${var.name_prefix}web-sg"
    description = "Security group for web access"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}web-sg"
    }
}

# ==================================================================
# 프라이빗 웹인스턴스용 보안그룹
resource "aws_security_group" "std17_internal_alb_sg" {
    name = "${var.name_prefix}private-web-sg"
    description = "Security group for private-web access"
    vpc_id = var.vpc_id

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}private-web-sg"
    }
}

# 보안그룹 규칙 추가: 외부 ALB에서 내부 ALB로의 트래픽 허용
resource "aws_security_group_rule" "std17_internal_alb_rule" {
    type        = "ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    
    # 소스로 어떤 보안 그룹을 추가할 지 추가할 보안그룹의 아이디 지정
    source_security_group_id = aws_security_group.std17_external_alb_sg.id
    # 규칙을 추가할 보안 그룹의 아이디
    security_group_id = aws_security_group.std17_internal_alb_sg.id
}