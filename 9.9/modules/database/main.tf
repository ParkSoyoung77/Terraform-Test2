resource "aws_db_subnet_group" "std17_db_subnet_group" {
    name = "std17-db-subnet-group"
    subnet_ids = var.subnet_ids

    tags = { Name = "std17-db-subnet-group"}
}

resource "aws_db_instance" "std17_mysql_instance" {
    identifier      = "std17-mysql-instance"
    engine          = "mysql"
    engine_version  = "8.0"
    instance_class  = "db.t3.micro"

    allocated_storage = 20 # 최소 사양

    db_name  = "testdb"
    username = "std17"
    password = "12341234"

    db_subnet_group_name = aws_db_subnet_group.std17_db_subnet_group.name
    availability_zone    = var.azs[0]

    vpc_security_group_ids = [
        var.mysql_sg_id
    ]

    # 백업(최소 7일)
    backup_retention_period = 7
    # 인스턴스 삭제 시, 마지막 백업 스냅샷의 생성 여부
    skip_final_snapshot     = true

    tags = { Name = "std17-mysql-instance"}
}

# ================================================================
# 보안 암호 생성
resource "aws_secretsmanager_secret" "mysql_password" {
    description = "RDS 데이터베이스 비밀번호"
    name        = "project/db/password"
}

# 보안 암호에 실제 사용할 암호 정의
resource "aws_secretsmanager_secret_version" "mysql_password_value" {
    secret_id = aws_secretsmanager_secret.mysql_password.id
    secret_string = jsonencode({
    username = "std17"
    password = random_password.mysql_password.result
  })
}

resource "random_password" "mysql_password" {
  length  = 16
  special = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}