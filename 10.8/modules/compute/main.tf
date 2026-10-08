# ====================================================
# 최신 Amazon Linux 2023 AMI (리전별 AMI ID 하드코딩 불필요)
# ====================================================
data "aws_ami" "al2023" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-2023.*-x86_64"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}

# ####################################################
# 1. NAT 인스턴스 — 프라이빗 서브넷의 외부 통신 담당
# ####################################################
resource "aws_instance" "nat" {
    ami                    = data.aws_ami.al2023.id
    instance_type          = var.nat_instance_type
    subnet_id              = var.nat_subnet_id
    vpc_security_group_ids = var.nat_sg_ids
    key_name               = var.key_name

    # NAT의 핵심: 자기 IP가 아닌 패킷도 주고받도록 Source/Dest Check 비활성화
    source_dest_check = false

    # 템플릿 변수가 없으므로 file() 로 그대로 사용
    user_data                   = file("${path.module}/scripts/nat_user_data.sh")
    user_data_replace_on_change = true # NAT는 상태가 없어서 재생성돼도 문제 없음

    lifecycle {
        ignore_changes = [ami] # 새 AMI가 나올 때마다 재생성되지 않도록
    }

    tags = {
        Name = "${var.tag_header}nat-instance"
    }
}

# 프라이빗 서브넷 → NAT 인스턴스 경로 (라우팅 테이블은 network 모듈에서 생성)
resource "aws_route" "private_nat" {
    for_each = var.private_route_table_ids

    route_table_id         = each.value
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = aws_instance.nat.primary_network_interface_id
}