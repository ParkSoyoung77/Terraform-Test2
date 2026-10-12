# ==================================================================
# [FinOps] EventBridge Scheduler — std17-finops-start
#   반복 일정 : 평일(월~금) 08:00 (Asia/Seoul)
#   유연한 기간 : 5분
#   대상      : Lambda Invoke (eventbridge_scheduler_finops)
#   페이로드   : {"action": "start"}
#   완료 후 작업 : NONE
# ==================================================================

resource "aws_scheduler_schedule" "finops_start" {
  name       = "std17-finops-start"
  group_name = "default"

  # 반복 일정 (cron: 분 시 일 월 요일 연도)
  schedule_expression          = "cron(0 8 ? * MON-FRI *)"
  schedule_expression_timezone = "Asia/Seoul"

  # 유연한 기간 5분 (08:00 ~ 08:05 사이 실행)
  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 5
  }

  # 일정 완료 후 작업: 없음
  action_after_completion = "NONE"

  target {
    arn      = aws_lambda_function.finops.arn          # 대상 API: Lambda Invoke
    role_arn = aws_iam_role.finops_scheduler_role.arn  # 기존 역할 사용
    input    = jsonencode({ action = "start" })        # 페이로드
  }
}

# ==================================================================
# [FinOps] EventBridge Scheduler — std17-finops-stop
#   반복 일정 : 평일(월~금) 19:00 (Asia/Seoul)
#   유연한 기간 : 5분
#   대상      : Lambda Invoke (eventbridge_scheduler_finops)
#   페이로드   : {"action": "stop"}
#   완료 후 작업 : NONE
# ==================================================================

resource "aws_scheduler_schedule" "finops_stop" {
  name       = "std17-finops-stop"
  group_name = "default"

  # 반복 일정 (cron: 분 시 일 월 요일 연도)
  schedule_expression          = "cron(0 19 ? * MON-FRI *)"
  schedule_expression_timezone = "Asia/Seoul"

  # 유연한 기간 5분 (19:00 ~ 19:05 사이 실행)
  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 5
  }

  # 일정 완료 후 작업: 없음
  action_after_completion = "NONE"

  target {
    arn      = aws_lambda_function.finops.arn          # 대상 API: Lambda Invoke
    role_arn = aws_iam_role.finops_scheduler_role.arn  # 기존 역할 사용
    input    = jsonencode({ action = "stop" })         # 페이로드
  }
}

# ==================================================================
# [Security] EventBridge 규칙 — std17-eventbridge-trail-policy
#   이벤트 버스 : default
#   이벤트 소스 : 기타 (사용자 지정 이벤트 패턴)
#   감지 대상   : CloudTrail 로 기록된 AuthorizeSecurityGroupIngress
#   대상        : Lambda 함수 (security_trail_revoke)
# ==================================================================

resource "aws_cloudwatch_event_rule" "trail_policy" {
  name           = "std17-eventbridge-trail-policy"
  event_bus_name = "default"

  # 사용자 지정 이벤트 패턴 (JSON)
  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AuthorizeSecurityGroupIngress"]
    }
  })

  tags = { Name = "std17-eventbridge-trail-policy" }
}

# 대상: AWS 서비스 → Lambda 함수 (security_trail_revoke)
resource "aws_cloudwatch_event_target" "trail_policy_lambda" {
  rule           = aws_cloudwatch_event_rule.trail_policy.name
  event_bus_name = "default"
  target_id      = "security-trail-revoke"
  arn            = aws_lambda_function.sg_revoke.arn
}

# EventBridge → Lambda 호출 권한
#   콘솔에서 Lambda 대상을 고르면 자동으로 붙는 리소스 기반 정책을 직접 만듦
resource "aws_lambda_permission" "allow_eventbridge_trail_policy" {
  statement_id  = "AllowEventBridgeInvokeTrailPolicy"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sg_revoke.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trail_policy.arn
}