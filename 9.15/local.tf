locals {
  common_tags = {
    Course      = "BIPA17"
    ManageBy    = "Terraform"
    Project     = "bipa17-Solution-Architect"
    Domain      = var.domain_name
    Environment = var.env_type # prod, dev, test, lab
    Owner       = "bipa17-instructor"
  }

  # 가용 영역을 local 블력에 변수로 정의
  azs = data.aws_availability_zones.available_az.names

  # VPC CIDR 블록을 local 변수로 정의
  vpc_cidr_block = "${var.cidr_header}.0.0/16"

  subnet_map = merge([
    for idx, key in var.subnet_type : {
      for i, az_name in local.azs : "${key}${split("-", az_name)[2]}" => {
        type = key
        az   = az_name
        cidr = "${var.cidr_header}.${i + (idx * 10 + 1)}.0/24"
        rt = key == "private" ? "${key}${split("-", az_name)[2]}" : (
          key
        )
      }
    }
  ]...)

  route_map = {
    for item in flatten([
      for type in var.subnet_type :
      type == "private" ? [
        for az in local.azs : {
          key  = "private${split("-", az)[2]}"
          type = type
        }
        ] : [
        {
          key  = type
          type = type
        }
      ]
      ]) : item.key => {
      type = item.type
    }
  }

  owner = var.owner
  tag_header = (var.owner != "" && var.env_type != "") ? "${var.owner}-${var.env_type}-" : (
    (var.owner != "") ? "${var.owner}-" : ""
  )
  vpc_options = var.vpc_options
  # domain
  domain_name = var.domain_name

  ami_id = data.aws_ami.ubuntu_24_04.id

  region = data.aws_region.current.region


  vpc_id      = module.mumbai_network.network.vpc.id
  subnets     = module.mumbai_network.network.subnets
  mysql_sg_id = module.mumbai_network.mysql_sg
}

output "route_map" {
  value = local.route_map
}
