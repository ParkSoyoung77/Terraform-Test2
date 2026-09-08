resource "aws_instance" "std17_ex_instance" {
    ami     = var.instance_ami
    instance_type = var.instance_type

    subnet_id = var.public_subnet_id
    key_name = "std17-key"

    root_block_device {
        volume_size = 20
        volume_type = "gp3"
        delete_on_termination = true # 인스턴스 삭제 시, 볼륨 같이 삭제
        tags = {
            Name = "std17-ex-volume"
        }
    }

    vpc_security_group_ids = [
        var.ssh_sg_id,
        var.external_alb_sg_id
    ]

    user_data                   = file("${path.module}/scripts/user_data.sh")
    user_data_replace_on_change = true
    
    tags = {
        Name = "std17-ex-instance"
    }
}

resource "aws_ami_from_instance" "std17_nginx_ami" {
    name = "std17-ex-nginx-ami"
    source_instance_id = aws_instance.std17_ex_instance.id

    # 재부팅하여 이미지 생성: false
    snapshot_without_reboot = false

    tags = {
        Name = "std17-ex-nginx-ami"
    }
}


resource "aws_launch_template" "std17_ex_lt" {
    name_prefix = "std17-ex-lt-"
    image_id    = aws_ami_from_instance.std17_nginx_ami.id
    instance_type = "t3.nano"

    vpc_security_group_ids = [
        var.ssh_sg_id,
        var.external_alb_sg_id
    ]

    # 시작 템플릿에서는 base64encode)를 통해 암호화 필요
    user_data = base64encode(<<-EOF
    #!/bin/bash
    systemctl start nginx
    systemctl enable nginx
    EOF
    )

    tag_specifications {
        resource_type = "instance"
        tags = { Name = "std17-ex-asg-instance"}
    }

    tag_specifications {
        resource_type = "volume"
        tags = { Name = "std17-ex-asg-instance-vol"}
    }

    tags = { Name = "std17-ex-asg-lt"}
}

# ===============================================
# 키페어
# ===============================================

# resource "aws_key_pair" "std17_lab_key" {
#     key_name = "std17-lab-key"
#     public_key = file("~/.ssh/id_rsa.pub")

#     tags = {
#         Name = "std17-lab-key"
#     }
# }