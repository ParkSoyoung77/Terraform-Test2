locals {
  cpu_metrics     = [for id in var.instance_ids : ["AWS/EC2", "CPUUtilization", "InstanceId", id]]
  status_metrics  = [for id in var.instance_ids : ["AWS/EC2", "StatusCheckFailed", "InstanceId", id]]
  net_in_metrics  = [for id in var.instance_ids : ["AWS/EC2", "NetworkIn", "InstanceId", id]]
  net_out_metrics = [for id in var.instance_ids : ["AWS/EC2", "NetworkOut", "InstanceId", id]]
  ebs_r_metrics   = [for id in var.instance_ids : ["AWS/EC2", "EBSReadBytes", "InstanceId", id]]
  ebs_w_metrics   = [for id in var.instance_ids : ["AWS/EC2", "EBSWriteBytes", "InstanceId", id]]
}