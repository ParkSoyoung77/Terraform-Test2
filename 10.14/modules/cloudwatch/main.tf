locals {
  metric_names = ["CPUUtilization", "StatusCheckFailed", "NetworkIn", "NetworkOut", "EBSReadBytes", "EBSWriteBytes"]

  # 지표별로 [인스턴스 ID 기준 + ASG 기준] 라인을 합침
  metrics = {
    for m in local.metric_names : m => concat(
      [for id in var.instance_ids : ["AWS/EC2", m, "InstanceId", id]],
      [for n in var.asg_names : ["AWS/EC2", m, "AutoScalingGroupName", n]]
    )
  }

  widget_defs = [
    {
      title  = "CPU 사용률 (%)", metric = "CPUUtilization", stat = "Average"
      extra = {
        yAxis       = { left = { min = 0, max = 100 } }
        annotations = { horizontal = [{ label = "${var.cpu_threshold}% 경고", value = var.cpu_threshold, color = "#d62728" }] }
      }
    },
    { title = "상태 검사 실패",       metric = "StatusCheckFailed", stat = "Maximum", extra = { view = "singleValue", sparkline = true } },
    { title = "Network In (Bytes)",  metric = "NetworkIn",         stat = "Sum",     extra = {} },
    { title = "Network Out (Bytes)", metric = "NetworkOut",        stat = "Sum",     extra = {} },
    { title = "EBS Read (Bytes)",    metric = "EBSReadBytes",      stat = "Sum",     extra = {} },
    { title = "EBS Write (Bytes)",   metric = "EBSWriteBytes",     stat = "Sum",     extra = {} },
  ]
}

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
        properties = { markdown = "# ${var.dashboard_name}\nNAT 인스턴스 / Nginx ASG / EKS 노드 모니터링" }
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