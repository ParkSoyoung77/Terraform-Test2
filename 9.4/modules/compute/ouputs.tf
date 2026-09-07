output "instance" {
    value = { for k, v in aws_instance.this : k => v.tags["Name"]}
}