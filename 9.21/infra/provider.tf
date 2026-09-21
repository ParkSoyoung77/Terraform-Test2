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
        tags = {
            Class = "bipa17"
            Owner = "std17"
        }
    }
}

# CodeStar Connections(GitHub 연동)가 오사카 리전에서 지원되지 않아
# 도쿄 리전용 provider alias를 추가로 정의합니다.
provider "aws" {
    alias  = "tokyo"
    region = "ap-northeast-1"
    default_tags {
        tags = {
            Class = "bipa17"
            Owner = "std17"
        }
    }
}