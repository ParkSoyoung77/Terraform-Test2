variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "dashboard_name" {
  type    = string
  default = "std17-instance-board"
}

variable "asgs" {
  description = "범례 표시 이름 => ASG 이름"
  type        = map(string)
  default     = {}
}

variable "period" {
  type    = number
  default = 300
}

variable "cpu_threshold" {
  type    = number
  default = 80
}

# =====================================================
variable "log_dashboard_name" {
  description = "로그 대시보드 이름"
  type        = string
  default     = "std17-log-board"
}

variable "syslog_group_name" {
  description = "CW 에이전트가 수집하는 시스템 로그 그룹"
  type        = string
  default     = "std17-system-syslog"
}