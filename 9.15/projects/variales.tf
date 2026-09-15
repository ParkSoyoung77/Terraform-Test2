variable "subnet_type" {
  description = "Subnet Type"
  type        = list(string)
  default     = []
}

variable "cidr_header" {
  description = "Network CIDR"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner Name"
  type        = string
  default     = ""
}

variable "env_type" {
  description = "Environment"
  type        = string
  default     = ""
}
# -------------------------------------------
# VPC 속성 정의
variable "vpc_options" {
  description = "VPC 상세 설정 옵션"
  type = object({
    instance_tenancy                      = optional(string, "default")
    enable_dns_support                    = optional(bool, true)
    enable_dns_hostnames                  = optional(bool, true)
    assign_generated_ipv6_cidr_block      = optional(bool, false)
    enable_network_address_usage_metrics  = optional(bool, false)
  })

  default = {
    instance_tenancy                      = "default"
    enable_dns_support                    = true
    enable_dns_hostnames                  = true
    assign_generated_ipv6_cidr_block      = false
    enable_network_address_usage_metrics  = false
  }
}

variable "create_nat_gateway" {
  description = "NAT Gateway의 생성 여부(true-생성 / false-미생성)"
  type        = bool
  default     = true
}

variable "ssh_key" {
  description = "SSH Key"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = ""
}
