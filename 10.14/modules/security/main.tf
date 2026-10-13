# ==================================================================
# ALB SG: 인터넷에서 HTTP 80
resource "aws_security_group" "std17_alb_sg" {
    name        = "${var.name_prefix}-alb-sg"
    vpc_id      = var.vpc_id
    description = "ALB SG - HTTP from internet"

    ingress {
        from_port   = 80
        to_port     = 80
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
        Name = "${var.name_prefix}-alb-sg"
    }
}

# ==================================================================
# EC2 SG: ALB에서 오는 80만 허용 (nginx 컨테이너 호스트 포트)
resource "aws_security_group" "std17_ec2_sg" {
    name        = "${var.name_prefix}-ec2-sg"
    vpc_id      = var.vpc_id
    description = "EC2 nginx docker SG - only from ALB"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.std17_alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-ec2-sg"
    }
}

# ==================================================================
# RDS SG: EC2 SG에서 3306 허용 (EKS 노드 허용 규칙은 루트 main.tf)
resource "aws_security_group" "std17_rds_sg" {
    name        = "${var.name_prefix}-rds-sg"
    vpc_id      = var.vpc_id
    description = "RDS SG - MySQL from app tiers only"

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-rds-sg"
    }
}

resource "aws_security_group_rule" "std17_rds_from_ec2" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_rds_sg.id
    source_security_group_id = aws_security_group.std17_ec2_sg.id
    description              = "ec2 to RDS"
}

# ==================================================================
# NAT 인스턴스 SG: VPC 내부에서 오는 모든 트래픽 허용 → 인터넷으로 전달
resource "aws_security_group" "std17_nat_sg" {
    name        = "${var.name_prefix}-nat-sg"
    vpc_id      = var.vpc_id
    description = "NAT instance SG - all traffic from VPC"

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-nat-sg"
    }
}

# ==================================================================
# SSH 점프 경로: 내 PC -> NAT 인스턴스(22) -> 프라이빗 EC2(22)
resource "aws_security_group_rule" "std17_nat_ssh_from_admin" {
    count = length(var.ssh_allowed_cidrs) > 0 ? 1 : 0

    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_group_id = aws_security_group.std17_nat_sg.id
    cidr_blocks       = var.ssh_allowed_cidrs
    description       = "SSH from admin PC to NAT(jump host)"
}

resource "aws_security_group_rule" "std17_ec2_ssh_from_nat" {
    type                     = "ingress"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_ec2_sg.id
    source_security_group_id = aws_security_group.std17_nat_sg.id
    description              = "SSH from NAT(jump host) to ASG instances"
}