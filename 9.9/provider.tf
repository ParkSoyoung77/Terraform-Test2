terraform {
    required_providers {
        aws = {
            source ="hashicorp/aws"
            version = "~> 6.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.6"
        }
    }
}

provider "aws"{
    region = "ap-northeast-3"
    default_tags {
        tags = local.common_tags
    }
}