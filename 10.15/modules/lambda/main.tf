data "archive_file" "log_saver" {
    type        = "zip"
    source_file = "${path.module}/src/log_saver.py"
    output_path = "${path.module}/build/log_saver.zip"
}

resource "aws_iam_role" "std17_lambda_role" {
    name = "${var.name_prefix}-log-lambda-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "lambda.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = { Name = "${var.name_prefix}-log-lambda-role" }
}

# CloudWatch Logs 기록 권한
resource "aws_iam_role_policy_attachment" "std17_lambda_basic" {
    role       = aws_iam_role.std17_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray 트레이스 전송 권한 (Active tracing 용)
resource "aws_iam_role_policy_attachment" "std17_lambda_xray" {
    role       = aws_iam_role.std17_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# fastapi-logs/ 경로에만 쓰기
resource "aws_iam_role_policy" "std17_lambda_s3_put" {
    name = "${var.name_prefix}-log-lambda-s3-put"
    role = aws_iam_role.std17_lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid      = "WriteFastapiLogs"
            Effect   = "Allow"
            Action   = "s3:PutObject"
            Resource = "${var.log_bucket_arn}/${var.log_prefix}/*"
        }]
    })
}

resource "aws_cloudwatch_log_group" "std17_lambda_logs" {
    name              = "/aws/lambda/${var.name_prefix}-log-saver"
    retention_in_days = 7
}

resource "aws_lambda_function" "std17_log_saver" {
    function_name    = "${var.name_prefix}-log-saver"
    role             = aws_iam_role.std17_lambda_role.arn
    filename         = data.archive_file.log_saver.output_path
    source_code_hash = data.archive_file.log_saver.output_base64sha256

    handler     = "log_saver.lambda_handler" # 파일명.함수명
    runtime     = "python3.14"
    timeout     = 10
    memory_size = 128

    environment {
        variables = {
            LOG_BUCKET = var.log_bucket_name
            LOG_PREFIX = var.log_prefix
        }
    }

    # X-Ray Active tracing: 함수 실행(초기화/호출 시간)을 트레이스 맵에 별도 노드로 표시
    tracing_config {
        mode = "Active"
    }

    depends_on = [
        aws_iam_role_policy_attachment.std17_lambda_basic,
        aws_iam_role_policy_attachment.std17_lambda_xray,
        aws_iam_role_policy.std17_lambda_s3_put,
        aws_cloudwatch_log_group.std17_lambda_logs,
    ]

    tags = { Name = "${var.name_prefix}-log-saver" }
}