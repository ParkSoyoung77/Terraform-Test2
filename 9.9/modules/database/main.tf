resource "aws_db_subnet_group" "std17_db_subnet_group" {
    name       = "std17-db-subnet-group"
    subnet_ids = var.private_subnet_ids

    tags = { Name = "std17-db-subnet-group" }
}

# ================================================================
# 보안 암호 생성
# ================================================================
resource "random_password" "create_random_password" {
  length            = 16
  special           = true
  override_special  = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "mysql_password" {
    description = "RDS 데이터베이스 비밀번호"
    name        = "project/db/password"
    recovery_window_in_days = 0 # 삭제 시 즉시 삭제, 대기기간 없음
}

# 보안 암호에 실제 사용할 암호 정의
resource "aws_secretsmanager_secret_version" "mysql_password_value" {
    secret_id = aws_secretsmanager_secret.mysql_password.id
    secret_string = jsonencode({
        engine   = "mysql"
        host     = aws_rds_cluster.std17_mysql_cluster.endpoint
        database = "testdb"
        username = "std17"
        password = random_password.create_random_password.result
        port     = 3306
    })
}

# ================================================================
# MySQL 클러스터
# ================================================================
# RDS MySQL 멀티AZ DB 클러스터
resource "aws_rds_cluster" "std17_mysql_cluster" {
    cluster_identifier         = "std17-rds-mysql-multi-az-cluster"
    engine                     = "mysql"
    engine_version             = "8.0.46"
    db_cluster_instance_class  = "db.c6gd.medium"

    # 볼륨 설정
    storage_type      = "gp3"
    allocated_storage = 100

    database_name   = "testdb"
    master_username = "std17"
    master_password = random_password.create_random_password.result

    db_subnet_group_name    = aws_db_subnet_group.std17_db_subnet_group.name
    vpc_security_group_ids  = [ var.mysql_sg_id ]
    skip_final_snapshot     = true

    # 수정할 때 볼륨으로 인한 에러 발생
    # 이에 최초 생성 이외 apply 때 볼륨 변경을 무시하기 위한 설정
    lifecycle {
        ignore_changes = [
            storage_type,
            allocated_storage,
            iops
        ]
    }

    tags = { Name = "std17-rds-mysql-multi-az-cluster"}
}

