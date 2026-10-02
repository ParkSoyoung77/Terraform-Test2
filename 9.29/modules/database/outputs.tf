output "secret_db_password" {
    value = jsondecode(aws_secretsmanager_secret_version.mysql_password_value.secret_string)["password"]
    sensitive = true
}