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
# EC2 SG: ALB에서 오는 80 + NAT(점프 호스트)에서 오는 22
#  ※ 인바운드는 전부 인라인 ingress 로 관리
#    (인라인 ingress + aws_security_group_rule 을 같은 SG에 섞으면
#     apply 때 SG 리소스가 별도 규칙을 지워버림)
resource "aws_security_group" "std17_ec2_sg" {
    name        = "${var.name_prefix}-ec2-sg"
    vpc_id      = var.vpc_id
    description = "EC2 nginx docker SG - only from ALB"

    ingress {
        description     = "HTTP from ALB to nginx"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.std17_alb_sg.id]
    }

    ingress {
        description     = "SSH from NAT(jump host)"
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.std17_nat_sg.id]
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
# NAT 인스턴스 SG: VPC 내부 전체 허용(NAT 역할) + 내 PC에서 SSH(점프 호스트)
resource "aws_security_group" "std17_nat_sg" {
    name        = "${var.name_prefix}-nat-sg"
    vpc_id      = var.vpc_id
    description = "NAT instance SG - all traffic from VPC"

    ingress {
        description = "all traffic from VPC (NAT)"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
    }

    # ssh_allowed_cidrs 가 비어 있으면 22번 규칙을 만들지 않음
    dynamic "ingress" {
        for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
        content {
            description = "SSH from admin PC"
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = var.ssh_allowed_cidrs
        }
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
