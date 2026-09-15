variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "region" {
  description = "REGION"
  type        = string
  default     = ""
}

variable "mysql_sg_id" {
  description = "MySQL Security Group"
  type        = string
  default     = ""
}

variable "azs" {
  description = "Network CIDR"
  type        = list(string)
  default     = []
}


variable "tag_header" {
  description = "Resource Name or Tag:Name Header"
  type        = string
  default     = ""
}
