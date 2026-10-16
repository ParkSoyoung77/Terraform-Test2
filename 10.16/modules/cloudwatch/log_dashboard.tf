resource "aws_cloudwatch_dashboard" "logs" {
  dashboard_name = var.log_dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# ${var.log_dashboard_name}\nCloudWatch Agent 수집 시스템 로그 (`${var.syslog_group_name}`)"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 2
        width  = 24
        height = 8
        properties = {
          title  = "최근 시스템 로그"
          region = var.region
          view   = "table"
          query  = <<-EOT
            SOURCE '${var.syslog_group_name}'
            | fields @timestamp, @logStream as instance, @message
            | sort @timestamp desc
            | limit 100
          EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 10
        width  = 24
        height = 8
        properties = {
          title  = "에러 / 실패 로그"
          region = var.region
          view   = "table"
          query  = <<-EOT
            SOURCE '${var.syslog_group_name}'
            | fields @timestamp, @logStream as instance, @message
            | filter @message like /(?i)(error|fail|denied)/
            | sort @timestamp desc
            | limit 100
          EOT
        }
      }
    ]
  })
}