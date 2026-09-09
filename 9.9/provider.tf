terraform {
    required_providers {
        aws = {
            source ="hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "aws"{
    region = "ap-northeast-3"
    default_tags {
        tags = local.common_tags
    }
}