locals {
  cpu_metrics     = [for label, name in var.asgs : ["AWS/EC2", "CPUUtilization",    "AutoScalingGroupName", name, { label = label }]]
  status_metrics  = [for label, name in var.asgs : ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", name, { label = label }]]
  net_in_metrics  = [for label, name in var.asgs : ["AWS/EC2", "NetworkIn",         "AutoScalingGroupName", name, { label = label }]]
  net_out_metrics = [for label, name in var.asgs : ["AWS/EC2", "NetworkOut",        "AutoScalingGroupName", name, { label = label }]]
  ebs_r_metrics   = [for label, name in var.asgs : ["AWS/EC2", "EBSReadBytes",      "AutoScalingGroupName", name, { label = label }]]
  ebs_w_metrics   = [for label, name in var.asgs : ["AWS/EC2", "EBSWriteBytes",     "AutoScalingGroupName", name, { label = label }]]
}