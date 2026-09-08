variable "subnet_ids" {
  type = list(string)
}

variable "azs" {
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}