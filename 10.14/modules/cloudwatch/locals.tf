locals {
  metric_names = ["CPUUtilization", "StatusCheckFailed", "NetworkIn", "NetworkOut", "EBSReadBytes", "EBSWriteBytes"]

  # 지표별로 ASG 라인 생성 (범례는 표시 이름으로)
  metrics = {
    for m in local.metric_names : m => [
      for label, name in var.asgs : ["AWS/EC2", m, "AutoScalingGroupName", name, { label = label }]
    ]
  }

  widget_defs = [
    {
      title  = "CPU 사용률 (%)"
      metric = "CPUUtilization"
      stat   = "Average"
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