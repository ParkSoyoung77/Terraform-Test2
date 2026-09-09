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

# ================================================================
# Cloudformation
# ================================================================

resource "aws_serverlessapplicationrepository_cloudformation_stack" "mysql_rotation" {
    # 클라우드 포메이션의 스택 이름
    name = "rds-mysql-cluster-rotation-stack"

    # 비밀번호 변경에 사용할 원본(기준) 함수(애플리케이션)의 ARN
    application_id = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSMySQLRotationSingleUser"

    # 클라우드포메이션의 IAM 생성 및 리소스정책을 정의할 수 있게 허용
    capabilities = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]

    # lambda 함수 동작에 필요한 설정(Parameter)
    parameters = {
        # 람다 함수의 이름
        functionName = "${var.name_prefix}rds-mysql-cluster-rotation-fn"

        # 보안 암호 endpoint
        endpoint = "https://secretsmanager.${var.aws_region}.amazonaws.com"

        # lambda 함수가 접속해야할 데이터베이스가 포함된 서브넷 ID
        vpcSubnetIds = join(",", var.private_subnet_ids)

        # lambda 함수에 적용할 보안그룹 ID
        vpcSecurityGroupIds = var.lambda_sg_id
    }
}

# 시크릿 매니저에 저장된 암호를 지정된 람다 함수와 연결하는 리소스 생성
resource "aws_secretsmanager_secret_rotation" "mysql_secret_rotation" {
    # 바꿀 대상(보안 암호) 지정
    secret_id = aws_secretsmanager_secret.mysql_password.id

    # 사용할 람다함수 정의
    rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.mysql_rotation.outputs["RotationLambdaARN"]

    # 규칙 정의
    rotation_rules {
        automatically_after_days = 30
    }
}