# ==================================================================
# 1. 대상 로그 그룹 (새로 생성)
# ==================================================================
resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = { Name = var.log_group_name }
}

# ==================================================================
# 2. 서비스 역할 (새 서비스 역할 생성 및 사용)
# ==================================================================
resource "aws_iam_role" "this" {
  name = "${var.flow_log_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.flow_log_name}-role" }
}

resource "aws_iam_role_policy" "this" {
  name = "${var.flow_log_name}-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

# ==================================================================
# 3. VPC 플로우 로그
#    필터: 전체 / 집계 간격: 10분 / CloudWatch Logs / AWS 기본 형식
# ==================================================================
resource "aws_flow_log" "this" {
  vpc_id                   = var.vpc_id
  traffic_type             = var.traffic_type
  max_aggregation_interval = var.max_aggregation_interval

  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.this.arn
  iam_role_arn         = aws_iam_role.this.arn

  # log_format 미지정 = AWS 기본 형식

  tags = { Name = var.flow_log_name }
}