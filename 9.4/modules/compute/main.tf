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