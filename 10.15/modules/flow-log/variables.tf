variable "vpc_id" {
  description = "플로우 로그를 생성할 VPC ID"
  type        = string
}

variable "flow_log_name" {
  description = "플로우 로그 Name 태그"
  type        = string
  default     = "std17-vpc-flow-log"
}

variable "log_group_name" {
  description = "대상 CloudWatch 로그 그룹 이름"
  type        = string
  default     = "std17VPCFrontLogs"
}

variable "traffic_type" {
  description = "필터: ALL / ACCEPT / REJECT"
  type        = string
  default     = "ALL"
}

variable "max_aggregation_interval" {
  description = "최대 집계 간격(초): 60 또는 600"
  type        = number
  default     = 600
}

variable "retention_in_days" {
  description = "로그 보존 기간(일). 0이면 만료 없음 (콘솔 기본값과 동일)"
  type        = number
  default     = 0
}