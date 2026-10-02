output "secret_db_password" {
    value = jsondecode(aws_secretsmanager_secret_version.mysql_password_value.secret_string)["password"]
    sensitive = true
}

output "db_secret_arn" {
    value = aws_secretsmanager_secret.mysql_password.arn
}

output "proxy_endpoint" {
    value = aws_db_proxy.proxy.endpoint
}

output "db_name" {
    value = aws_db_instance.std17_mysql.db_name
}