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