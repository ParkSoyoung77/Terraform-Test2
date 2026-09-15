# ################################################################################
# Terraform Block 
# ================================================================================
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>6.0" # 6.0~<7.0
    }
  }
  backend "s3" {
    bucket      = "bipa17-instructor-bucket"                             # 위에서 만든 S3 버킷 이름
    key         = "TerraformState/Lab/project-module/terraform.tfstate"  # 버킷 내 저장 경로
    region      = "ap-south-1"                                           # 리전
    dynamodb_table  = "std17-terraform-lock-table"                             # DynamoDB 테이블 이름
    encrypt     = true                                                   # 상태 파일 암호화 여부
  }
  
#  required_providers {
#    google = {
#      source = "hashicorp/google"
#      version = "~>6.0" # 6.0~<7.0
#    }
#  }
}

# ################################################################################
# Provider Block
# ================================================================================
provider "aws" {
  region = "ap-south-1" # AWS CLI 환경설정값이 우선함.

  # 기본 태그 설정: 태라폼으로 생성한 리소스들에 추가
  default_tags {
    tags  =  local.common_tags 
  }
}

# 별칭을 사용한 추가 리전 (서울)
provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"

  default_tags {
    tags  =  local.common_tags 
  }
}