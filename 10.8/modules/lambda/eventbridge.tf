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