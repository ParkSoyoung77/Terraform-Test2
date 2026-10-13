output "db_subnet_group_name" {
    description = "RDS 서브넷 그룹 이름"
    value       = aws_db_subnet_group.std17_rds_subnet_group.name
}

output "db_endpoint" {
    description = "MySQL DNS"
    value       = aws_db_instance.std17_mysql.address
}

output "db_name" {
    description = "데이터베이스 이름"
    value       = var.db_name
}

output "db_secret_arn" {
    description = "마스터 계정 Secrets Manager ARN"
    value       = aws_secretsmanager_secret.std17_mysql_master.arn
}
