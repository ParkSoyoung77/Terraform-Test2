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

# ================================================================
# RDS 프록시
# ================================================================
resource "aws_iam_role" "proxy_role" {
    name = "${local.tag_header}rds-proxy-secrets-role"

    assume_role_policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "rds.amazonaws.com"
            }
        }]
    })

    tags = {Name="${local.tag_header}rds-proxy-secrets-role"}
}

resource "aws_iam_role_policy" "proxy_policy" {
    name = "${local.tag_header}rds-proxy-secrets-proxy_policy"
    role = aws_iam_role.proxy_role.id

    policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = [
                "secretsmanager:GetSecretValue"
            ]
            Resource = [aws_secretsmanager_secret.mysql_password.arn]
        }]
    })
}

resource "aws_db_proxy" "proxy" {
    name = "${local.tag_header}rds-mysql-cluster-proxy"

    engine_family = "MYSQL"

    # 클라이언트-프록시 연결 이후, 연결 유지 시간
    # 30분동안 클라이언트와 상호간 트래픽이 발생하지않을경우 연결 종료
    idle_client_timeout = 1800

    # 상시 적용: 클라이언트와 프록시 간 데이터 암호화
    require_tls = true

    # 사용할 서브넷 설정 목록
    vpc_subnet_ids = var.private_subnet_ids

    # Secrets Manager 사용 권한 설정
    role_arn = aws_iam_role.proxy_role.arn

    # 보안 그룹 설정
    vpc_security_group_ids = [ var.mysql_sg_id ]

    # 인증 설정
    auth {
        # description = "인증 방식에 대한 설명"
        # 사용자가 프록시에 어떤 방식으로 로그인 할지 정의
        # REQUIRED: IAM 토큰을 이용하여 로그인
        # DISABLED: 일반 DB 계정 / 보안 암호를 이용한 인증 사용
        iam_auth = "DISABLED"

        # 데이터베이스로의 로그인하는 방식은 고정
        # SECRETS: Secrets Manager 사용한 로그인 방식 사용
        auth_scheme = "SECRETS"

        # 사용할 Secrets Manager 설정(ARN)
        secret_arn = aws_secretsmanager_secret.mysql_password.arn
    }

    tags = {Name = "${local.tag_header}rds-mysql-cluster-proxy"}
}

# Proxy와 기본 타겟 그룹 연결
resource "aws_db_proxy_default_target_group" "proxy_target_group" {
    db_proxy_name = aws_db_proxy.proxy.name

    # 접속자들 관리 환경 정의
    connection_pool_config {
        # 로그인 유지 시간(초)
        connection_borrow_timeout = 300

        # 최대 연결 수 
        # 데이터베이스의 최대 연결 허용치에 대한 비율을 정의
        max_connections_percent = 100

        # 최대 연결 수 중 idle 상태의 연결을 유지시킬 비율
        max_idle_connections_percent = 50
    }
}

# RDS Proxy와 실제 백엔드 데이터베이스(Aurora Cluster)를 상호 연결
resource "aws_db_proxy_target" "proxy_target_cluster" {
    # Proxy와의 연결 구성
    db_proxy_name = aws_db_proxy.proxy.name

    # proxy_target_group과의 연결 구성
    target_group_name = aws_db_proxy_default_target_group.proxy_target_group.name

    # Databast 연결 구성
    db_cluster_identifier = aws_rds_cluster.std17_mysql_cluster.id
}
# # ================================================================
# # Cloudformation
# # ================================================================

# resource "aws_serverlessapplicationrepository_cloudformation_stack" "mysql_rotation" {
#     # 클라우드 포메이션의 스택 이름
#     name = "rds-mysql-cluster-rotation-stack"

#     # 비밀번호 변경에 사용할 원본(기준) 함수(애플리케이션)의 ARN
#     application_id = ""

#     # 클라우드포메이션의 IAM 생성 및 리소스정책을 정의할 수 있게 허용
#     capabilities = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]

#     # lambda 함수 동작에 필요한 설정(Parameter)
#     parameters = {
#         # 람다 함수의 이름
#         functionName = "${var.name_prefix}rds-mysql-cluster-rotation-fn"

#         # 보안 암호 endpoint
#         endpoint = "https://secretsmanager.${var.aws_region}.amazonaws.com"

#         # lambda 함수가 접속해야할 데이터베이스가 포함된 서브넷 ID
#         vpcSubnetIds = join(",", var.private_subnet_ids)

#         # lambda 함수에 적용할 보안그룹 ID
#         vpcSecurityGroupIds = var.lambda_sg_id
#     }
# }

# # 시크릿 매니저에 저장된 암호를 지정된 람다 함수와 연결하는 리소스 생성
# resource "aws_secretsmanager_secret_rotation" "mysql_secret_rotation" {
#     # 바꿀 대상(보안 암호) 지정
#     secret_id = aws_secretsmanager_secret.mysql_password.id

#     # 사용할 람다함수 정의
#     rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.mysql_rotation.outputs["RotationLambdaARN"]

#     # 규칙 정의
#     rotation_rules {
#         automatically_after_days = 30
#     }
# }