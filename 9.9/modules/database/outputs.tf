# 시크릿 매니저 보안 암호 반환
output "secret_db_password" {
    value = aws_secretsmanager_secret_version.mysql_password_value.secret_string
    sensitive = true
}