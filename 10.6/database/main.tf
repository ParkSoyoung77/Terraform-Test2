# # ================================================================
# # DB 서브넷 그룹
# # ================================================================
# resource "aws_db_subnet_group" "std17_db_subnet_group" {
#     # 고정 이름 대신 접두사 사용 → 교체 시 새 이름으로 먼저 생성 가능
#     name_prefix = "std17-db-subnet-group-"
#     subnet_ids  = var.private_subnet_ids

#     # 사용 중인 서브넷 그룹은 수정 불가 → 새로 만든 후 기존 것 삭제
#     lifecycle {
#         create_before_destroy = true
#     }

#     tags = { Name = "std17-db-subnet-group" }
# }

# # ================================================================
# # 보안 암호 생성
# # ================================================================
# resource "random_password" "create_random_password" {
#     length           = 16
#     special          = true
#     override_special = "!#$%^&*()-_=+[]{}<>:?"
# }

# resource "aws_secretsmanager_secret" "mysql_password" {
#     description             = "RDS 데이터베이스 비밀번호"
#     name                    = "project/db/password"
#     recovery_window_in_days = 0 # 삭제 시 즉시 삭제, 대기기간 없음
# }

# # 보안 암호에 실제 사용할 암호 정의
# resource "aws_secretsmanager_secret_version" "mysql_password_value" {
#     secret_id = aws_secretsmanager_secret.mysql_password.id
#     secret_string = jsonencode({
#         engine   = "mysql"
#         host     = aws_db_instance.std17_mysql.address
#         database = "testdb"
#         username = "std17"
#         password = random_password.create_random_password.result
#         port     = 3306
#     })
# }

# # ================================================================
# # MySQL DB 인스턴스 (단일 AZ)
# # ================================================================
# resource "aws_db_instance" "std17_mysql" {
#     identifier     = "std17-rds-mysql"
#     engine         = "mysql"
#     engine_version = "8.0.46"
#     instance_class = "db.t3.micro"

#     # 볼륨 설정
#     storage_type      = "gp3"
#     allocated_storage = 20

#     db_name  = "testdb"
#     username = "std17"
#     password = random_password.create_random_password.result

#     db_subnet_group_name   = aws_db_subnet_group.std17_db_subnet_group.name
#     vpc_security_group_ids = [ var.mysql_sg_id ]

#     multi_az            = false
#     publicly_accessible = false
#     skip_final_snapshot = true

#     # 서브넷 그룹 교체 시 DB도 재생성 (같은 VPC 내 서브넷 그룹 이동 불가)
#     lifecycle {
#         replace_triggered_by = [aws_db_subnet_group.std17_db_subnet_group.id]
#     }

#     tags = { Name = "std17-rds-mysql" }
# }

# # ================================================================
# # RDS 프록시
# # ================================================================
# resource "aws_iam_role" "proxy_role" {
#     name = "${local.tag_header}rds-proxy-secrets-role"

#     assume_role_policy = jsonencode ({
#         Version = "2012-10-17"
#         Statement = [{
#             Action = "sts:AssumeRole"
#             Effect = "Allow"
#             Principal = {
#                 Service = "rds.amazonaws.com"
#             }
#         }]
#     })

#     tags = {Name="${local.tag_header}rds-proxy-secrets-role"}
# }

# resource "aws_iam_role_policy" "proxy_policy" {
#     name = "${local.tag_header}rds-proxy-secrets-proxy_policy"
#     role = aws_iam_role.proxy_role.id

#     policy = jsonencode ({
#         Version = "2012-10-17"
#         Statement = [{
#             Effect = "Allow"
#             Action = [
#                 "secretsmanager:GetSecretValue"
#             ]
#             Resource = [aws_secretsmanager_secret.mysql_password.arn]
#         }]
#     })
# }

# resource "aws_db_proxy" "proxy" {
#     name = "${local.tag_header}rds-mysql-cluster-proxy"

#     engine_family = "MYSQL"

#     # 클라이언트-프록시 연결 이후, 연결 유지 시간
#     # 30분동안 클라이언트와 상호간 트래픽이 발생하지않을경우 연결 종료
#     idle_client_timeout = 1800

#     # 상시 적용: 클라이언트와 프록시 간 데이터 암호화
#     require_tls = true

#     # 사용할 서브넷 설정 목록
#     vpc_subnet_ids = var.private_subnet_ids

#     # Secrets Manager 사용 권한 설정
#     role_arn = aws_iam_role.proxy_role.arn

#     # 보안 그룹 설정
#     vpc_security_group_ids = [ var.mysql_sg_id ]

#     # 인증 설정
#     auth {
#         # description = "인증 방식에 대한 설명"
#         # 사용자가 프록시에 어떤 방식으로 로그인 할지 정의
#         # REQUIRED: IAM 토큰을 이용하여 로그인
#         # DISABLED: 일반 DB 계정 / 보안 암호를 이용한 인증 사용
#         iam_auth = "DISABLED"

#         # 데이터베이스로의 로그인하는 방식은 고정
#         # SECRETS: Secrets Manager 사용한 로그인 방식 사용
#         auth_scheme = "SECRETS"

#         # 사용할 Secrets Manager 설정(ARN)
#         secret_arn = aws_secretsmanager_secret.mysql_password.arn

#         # 클라이언트 → 프록시 비밀번호 인증 방식
#         # 생략 시 AWS가 기본값을 채워 넣어 plan마다 변경으로 표시되므로 명시
#         client_password_auth_type = "MYSQL_NATIVE_PASSWORD"
#     }

#     tags = {Name = "${local.tag_header}rds-mysql-cluster-proxy"}
# }

# # Proxy와 기본 타겟 그룹 연결
# resource "aws_db_proxy_default_target_group" "proxy_target_group" {
#     db_proxy_name = aws_db_proxy.proxy.name

#     # 접속자들 관리 환경 정의
#     connection_pool_config {
#         # 로그인 유지 시간(초)
#         connection_borrow_timeout = 300

#         # 최대 연결 수
#         # 데이터베이스의 최대 연결 허용치에 대한 비율을 정의
#         max_connections_percent = 100

#         # 최대 연결 수 중 idle 상태의 연결을 유지시킬 비율
#         max_idle_connections_percent = 50
#     }

#     # Proxy 재생성 시 타겟 그룹 설정도 다시 적용
#     lifecycle {
#         replace_triggered_by = [aws_db_proxy.proxy.id]
#     }
# }

# # RDS Proxy와 실제 백엔드 데이터베이스(단일 인스턴스)를 상호 연결
# resource "aws_db_proxy_target" "proxy_target_instance" {
#     db_proxy_name     = aws_db_proxy.proxy.name
#     target_group_name = aws_db_proxy_default_target_group.proxy_target_group.name

#     db_instance_identifier = aws_db_instance.std17_mysql.identifier

#     # Proxy 또는 DB가 재생성되면 타겟 재등록
#     lifecycle {
#         replace_triggered_by = [
#             aws_db_proxy.proxy.id,
#             aws_db_instance.std17_mysql.id,
#         ]
#     }
# }