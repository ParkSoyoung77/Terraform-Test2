resource "aws_db_subnet_group" "std17_rds_subnet_group" {
    name       = "${var.name_prefix}-db-subnet-group"
    subnet_ids = var.private_subnet_ids
    tags = {
        Name = "${var.name_prefix}-db-subnet-group"
    }
}

# ==================================================================
# 마스터 비밀번호 (Secrets Manager)
resource "random_password" "std17_mysql_master" {
    length  = 20
    special = false
}

resource "aws_secretsmanager_secret" "std17_mysql_master" {
    name = "${var.name_prefix}-rds-master-secret"

    # destroy 후 같은 이름으로 바로 재생성할 수 있도록 즉시 삭제
    recovery_window_in_days = 0

    tags = {
        Name = "${var.name_prefix}-rds-master-secret"
    }
}

resource "aws_secretsmanager_secret_version" "std17_mysql_master" {
    secret_id = aws_secretsmanager_secret.std17_mysql_master.id
    secret_string = jsonencode({
        username = var.master_username
        password = random_password.std17_mysql_master.result
        engine   = "mysql"
        host     = aws_db_instance.std17_mysql.address
        port     = aws_db_instance.std17_mysql.port
        dbname   = var.db_name
    })
}

# ==================================================================
# RDS MySQL 단일 DB 인스턴스 
resource "aws_db_instance" "std17_mysql" {
    identifier              = "${var.name_prefix}-mysql"
    engine                  = "mysql"
    engine_version          = var.engine_version
    instance_class          = var.instance_class
    allocated_storage       = 20
    storage_type            = "gp3"
    storage_encrypted       = true
    db_name                 = var.db_name
    username                = var.master_username
    password                = random_password.std17_mysql_master.result
    db_subnet_group_name    = aws_db_subnet_group.std17_rds_subnet_group.name
    vpc_security_group_ids  = [var.security_group_id]
    multi_az                = false
    publicly_accessible     = false
    backup_retention_period = 0
    skip_final_snapshot     = true
    apply_immediately       = true

    tags = {
        Name = "${var.name_prefix}-mysql"
    }
}
