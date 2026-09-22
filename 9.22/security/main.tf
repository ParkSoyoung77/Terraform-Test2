# SSH용
resource "aws_security_group" "std17_ssh_sg" {
    name = "${var.tag_header}internal-ssh-sg"
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
        Name = "${var.tag_header}internal-ssh-sg"
    }
}

# ALB용
# ALB용 (외부)
resource "aws_security_group" "std17_external_alb_sg" {
    name = "${var.tag_header}web-sg"
    description = "Security group for web access"
    vpc_id = var.vpc_id

    dynamic "ingress" {
        for_each = [80, 443]
        content {
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
        Name = "${var.tag_header}web-sg"
    }
}

# 내부 ALB용 (HTTP/HTTPS)
resource "aws_security_group" "std17_internal_alb_sg" {
    name = "${var.tag_header}internal-alb-sg"
    description = "Security group for internal ALB"
    vpc_id = var.vpc_id

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.std17_external_alb_sg.id]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = [aws_security_group.std17_external_alb_sg.id]
    }

    ingress {
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

# ==========================================================
# GitLab용
resource "aws_security_group" "std17_gitlab_sg" {
    name = "${var.tag_header}gitlab-sg"
    description = "Security group for GitLab EE SSH Port"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 2222
        to_port     = 2222
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
        Name = "${var.tag_header}gitlab-sg"
    }
}