variable "fullaccess_role_name" {
  description = "S3 FullAccess IAM role name"
  type        = string
  default     = "std17-AmazonS3FullAccess-role"
}

variable "fullaccess_policy_arn" {
  description = "S3 FullAccess에 연결할 관리형 정책 ARN"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

variable "role_description" {
  description = "IAM role description (공통)"
  type        = string
  default     = "Allow Ec2 Instance to call AWS services on your behalf"
}

variable "tags" {
  description = "Tags to apply to the IAM roles"
  type        = map(string)
  default     = {}
}
