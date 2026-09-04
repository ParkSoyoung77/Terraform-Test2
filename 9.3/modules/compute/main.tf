resource "aws_instance" "this" {
    ami     = var.instance_ami
    instance_type = var.instance_type

    tags={
        Name: "${var.name_prefix}instance"
    }
}