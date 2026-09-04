locals {
  common_tags = {
    Class = "bipa17"
    Owner = "std17"
  }
}

locals {
  azs = data.aws_availability_zones.available_az.names
}