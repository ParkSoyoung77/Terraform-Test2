resource "aws_instance" "std17_ex_instance" {
    ami     = var.instance_ami
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    key_name = "std17-key"

    root_block_device {
        volume_size = 20
        volume_type = "gp3"
        delete_on_termination = true
        tags = {
            Name = "std17-ex-volume"
        }
    }

    ebs_block_device {
        device_name = "/dev/sdf"
        volume_size = 30
        volume_type = "gp3"
        delete_on_termination = true
        tags = {
            Name = "std17-ex-extra-volume"
        }
    }

    vpc_security_group_ids = [
        var.ssh_sg_id,
        var.external_alb_sg_id,
        var.gitlab_sg_id,
    ]

    user_data                   = file("${path.module}/scripts/user_data.sh")
    user_data_replace_on_change = true

    tags = {
        Name = "std17-ex-instance"
    }
}

# =========================================================
# S3 엔드포인트 설정
# =========================================================
data "aws_vpc_endpoint_service" "s3" {
    service         = "s3"
    service_type    = "Gateway"
}

resource "aws_vpc_endpoint" "s3_endpoint" {
    vpc_id            = var.vpc_id
    service_name      = data.aws_vpc_endpoint_service.s3.service_name

    vpc_endpoint_type = "Gateway"

    route_table_ids   = values(var.private_route_table_ids)

    tags = { Name = "${local.tag_header}s3-endpoint"}
}