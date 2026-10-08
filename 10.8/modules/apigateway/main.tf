# ==================================================================
# HTTP API (브라우저 호출용, CORS는 API Gateway에서 처리)
# ==================================================================
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.tag_header}s3-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }

  tags = { Name = "${var.tag_header}s3-api" }
}

# $default 스테이지 + 자동 배포 → URL 뒤에 스테이지 이름이 붙지 않음
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# ==================================================================
# 경로별 Lambda 연결 (var.routes 에 항목을 추가하면 경로가 늘어남)
# ==================================================================
resource "aws_apigatewayv2_integration" "this" {
  for_each = var.routes

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"
}

# API Gateway가 Lambda를 호출할 수 있도록 허용
resource "aws_lambda_permission" "this" {
  for_each = var.routes

  statement_id  = "AllowApiGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}