locals {
  trail_name        = var.trail_name
  trail_bucket_name = var.trail_bucket_name
  account_id        = data.aws_caller_identity.current.account_id

  trail_tags = {
    Name  = var.trail_name
    Owner = var.owner
  }
}