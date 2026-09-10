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
        Name = "${var.name_prefix}web-sg"
    }
}

# ==========================================================
# NACL
resource "aws_network_acl" "std17_ex_nacl" {
    vpc_id = var.vpc_id

    ingress {
        rule_no    = 90
        protocol   = "tcp"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 22
        to_port    = 22
    }

    ingress {
        rule_no    = 100
        protocol   = "tcp"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }

    ingress {
        rule_no    = 110
        protocol   = "tcp"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
    }

    ingress {
        rule_no    = 120
        protocol   = "tcp"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }

    egress {
        rule_no    = 100
        protocol   = "-1"
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    tags = {
        Name = "${var.name_prefix}ex-nacl"
    }
}

# 서브넷 연결
resource "aws_network_acl_association" "std17_ex_nacl_assoc"{
    count = length(var.public_subnet_ids)

    subnet_id     = var.public_subnet_ids[count.index]
    network_acl_id = aws_network_acl.std17_ex_nacl.id
}