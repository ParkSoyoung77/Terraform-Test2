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

    # 백업(최소 7일)
    backup_retention_period = 7
    # 인스턴스 삭제 시, 마지막 백업 스냅샷의 생성 여부
    skip_final_snapshot     = true

    tags = { Name = "std17-mysql-instance"}
}