# resource "aws_instance" "this" {
#     for_each = toset(["logs", "media", "backup"])
#     ami     = var.instance_ami
#     instance_type = var.instance_type

#     subnet_id = var.public_subnet_ids[0]

#     tags={
#         Name: "${var.name_prefix}${each.key}-instance"
#     }
# }

resource "aws_instance" "this" {
    for_each = {
        "a" = "logs" 
        "b" = "media" 
        "c" = "backup"
    }
    ami     = var.instance_ami
    instance_type = var.instance_type

    subnet_id = var.public_subnet_ids[0]

    tags={
        Name: "${var.name_prefix}${each.value}-instance"
    }
}