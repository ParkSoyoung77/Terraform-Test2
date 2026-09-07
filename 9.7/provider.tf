terraform {
    required_providers {
        aws = {
            source ="hashicorp/aws"
            version = "~> 6.0"
        }
    }

    # 협업을 위한 상태 값 공유 저장소 설정
    backend "s3" {
        bucket = "std17-instructor-terraform-state-bucket"
        key    = "TerraformState/Lab/ex-network/terraform.tfstate"  #버킷내 저장경로
        region = "ap-northeast-3"
        dynamodb_table = "std17-lab-lock-table"
        encrypt = true
    }
}

provider "aws"{
    region = "ap-northeast-3"
    default_tags {
        tags = local.common_tags
    }
}