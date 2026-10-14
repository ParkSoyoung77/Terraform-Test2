resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = concat(
      [{
        type       = "text"
        x          = 0
        y          = 0
        width      = 24
        height     = 2
        properties = { markdown = "# ${var.dashboard_name}\nNginx ASG / EKS 노드 모니터링" }
      }],
      [for i, w in local.widget_defs : {
        type   = "metric"
        x      = (i % 2) * 12
        y      = 2 + floor(i / 2) * 6
        width  = 12
        height = 6
        properties = merge({
          title   = w.title
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = w.stat
          period  = var.period
          metrics = local.metrics[w.metric]
        }, w.extra)
      }]
    )
  })
}