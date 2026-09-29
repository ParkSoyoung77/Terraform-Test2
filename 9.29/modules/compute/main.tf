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

# ####################################################
# 2. GitLab 인스턴스
# ####################################################

# 고정 퍼블릭 IP — GitLab external_url 에 사용
# (인스턴스보다 먼저 만들어야 user data에 IP를 넣을 수 있어서 association을 따로 둠)
# ※ aws_eip 안에 instance = aws_instance.gitlab.id 를 쓰면
#   EIP → 인스턴스 → user data → EIP 순환 참조가 생겨 배포 불가
resource "aws_eip" "gitlab" {
    domain = "vpc"

    tags = {
        Name = "${var.tag_header}gitlab-eip"
    }
}

resource "aws_instance" "gitlab" {
    ami                    = data.aws_ami.al2023.id
    instance_type          = var.gitlab_instance_type
    subnet_id              = var.gitlab_subnet_id
    vpc_security_group_ids = var.gitlab_sg_ids
    key_name               = var.key_name

    # 루트 볼륨: swap 4GB + GitLab 이미지 때문에 기본 8GB로는 부족
    root_block_device {
        volume_size           = var.gitlab_root_volume_size
        volume_type           = "gp3"
        delete_on_termination = true

        tags = {
            Name = "${var.tag_header}gitlab-root-volume"
        }
    }

    # GitLab 데이터용 추가 볼륨 → 인스턴스 안에서 /dev/nvme1n1 로 보임
    # 인스턴스에 인라인으로 붙여야 부팅 시점(user data 실행 전)에 이미 연결되어 있음
    ebs_block_device {
        device_name           = "/dev/sdf"
        volume_size           = var.gitlab_data_volume_size
        volume_type           = "gp3"
        delete_on_termination = true

        tags = {
            Name = "${var.tag_header}gitlab-data-volume"
        }
    }

    # [user data 템플릿 치환]
    # templatefile(경로, 맵) : 두 번째 인자 맵의 키가 템플릿 안의 변수가 됨
    #   → gitlab_user_data.sh.tftpl 의 gitlab_host 자리에 EIP 주소가 들어감
    #   → 템플릿 변수라서 variable 블록을 따로 만들 필요 없음
    # 배포 순서 (Terraform이 참조 관계를 보고 자동으로 정함)
    #   1) aws_eip.gitlab 생성 → 퍼블릭 IP 확정
    #   2) 그 IP로 user data 렌더링 (hostname / external_url 에 IP가 박힘)
    #   3) aws_instance.gitlab 생성 → 부팅 시 user data 실행
    #   4) aws_eip_association.gitlab 으로 EIP를 인스턴스에 연결
    user_data = templatefile("${path.module}/scripts/gitlab_user_data.sh.tftpl", {
        gitlab_host = aws_eip.gitlab.public_ip
    })

    # [lifecycle 주의]
    # - ami       : 새 AMI가 나올 때마다 인스턴스(= GitLab 데이터)가 교체되지 않도록 무시
    # - user_data : user data를 수정해도 인스턴스가 교체되지 않도록 무시
    #   ※ 그래서 EIP가 바뀌거나 스크립트를 고쳐도 이미 떠 있는 GitLab에는 자동 반영되지 않음
    #     → 인스턴스에서 /opt/gitlab/docker-compose.yaml 을 직접 수정하거나
    #     → terraform apply -replace=module.compute.aws_instance.gitlab 로 재생성 (GitLab 데이터 초기화됨)
    lifecycle {
        ignore_changes = [ami, user_data]
    }

    tags = {
        Name = "${var.tag_header}gitlab-instance"
    }
}

resource "aws_eip_association" "gitlab" {
    instance_id   = aws_instance.gitlab.id
    allocation_id = aws_eip.gitlab.id
}