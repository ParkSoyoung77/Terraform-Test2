# ※ SG description / 규칙 description 은 한글 불가 (ASCII만 허용) → 영문으로 작성

# ==========================================================
# NAT 인스턴스용
# - VPC 내부(프라이빗 서브넷)에서 오는 모든 트래픽을 받아 인터넷으로 전달
# - 관리용 SSH
# ==========================================================
resource "aws_security_group" "nat" {
    name        = "${var.tag_header}nat-sg"
    description = "NAT instance"
    vpc_id      = var.vpc_id

    ingress {
        description = "All traffic from VPC (NAT)"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
    }

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = var.admin_cidr_blocks
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.tag_header}nat-sg"
    }
}

# ==========================================================
# GitLab 인스턴스용
# - 80/443 : 웹 UI
# - 2222   : GitLab SSH (git clone/push) — 컨테이너 22번으로 포워딩됨
# ==========================================================
resource "aws_security_group" "gitlab" {
    name        = "${var.tag_header}gitlab-sg"
    description = "GitLab CE web and git SSH"
    vpc_id      = var.vpc_id

    dynamic "ingress" {
        for_each = {
            "HTTP"       = 80
            "HTTPS"      = 443
            "GitLab SSH" = 2222
        }

        content {
            description = ingress.key
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.tag_header}gitlab-sg"
    }
}

# ==========================================================
# SSH용 (인스턴스 관리 접속)
# ==========================================================
resource "aws_security_group" "ssh" {
    name        = "${var.tag_header}ssh-sg"
    description = "SSH access"
    vpc_id      = var.vpc_id

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = var.admin_cidr_blocks
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.tag_header}ssh-sg"
    }
}

# ==========================================================
# 외부 ALB용 (추후 ALB 연결 시 사용)
# ==========================================================
resource "aws_security_group" "external_alb" {
    name        = "${var.tag_header}external-alb-sg"
    description = "External ALB"
    vpc_id      = var.vpc_id

    dynamic "ingress" {
        for_each = {
            "HTTP"  = 80
            "HTTPS" = 443
        }

        content {
            description = ingress.key
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.tag_header}external-alb-sg"
    }
}

# ==========================================================
# 내부 ALB용 (추후 ALB 연결 시 사용)
# - 80/443 : 외부 ALB에서만
# - 8000   : VPC 내부에서
# ==========================================================
resource "aws_security_group" "internal_alb" {
    name        = "${var.tag_header}internal-alb-sg"
    description = "Internal ALB"
    vpc_id      = var.vpc_id

    dynamic "ingress" {
        for_each = {
            "HTTP from external ALB"  = 80
            "HTTPS from external ALB" = 443
        }

        content {
            description     = ingress.key
            from_port       = ingress.value
            to_port         = ingress.value
            protocol        = "tcp"
            security_groups = [aws_security_group.external_alb.id]
        }
    }

    ingress {
        description = "App port from VPC"
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.tag_header}internal-alb-sg"
    }
}

# MySQL용
resource "aws_security_group" "std17_mysql_sg" {
    name = "${var.tag_header}mysql-sg"
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
        Name = "${var.tag_header}mysql-sg"
    }
}

# Lambda용
resource "aws_security_group" "std17_lambda_sg" {
    name   = "${var.tag_header}lambda-sg"
    vpc_id = var.vpc_id

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.tag_header}lambda-sg" }
}