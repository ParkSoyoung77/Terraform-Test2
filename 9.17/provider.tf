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
        tags = {
            Class = "bipa17"
            Owner = "std17"
        }
    }
}

# =============================================================
# 상태 파일 저장(공유)을 위한 버킷 생성 및 버전 활성화
# =============================================================
resource "aws_s3_bucket" "terraform_state" {
    bucket = "std17-instructor-study-bucket"

    lifecycle {
        prevent_destroy = true
    }

    tags={ Name = "std17-instructor-study-bucket" }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# =============================================================
# 배포중 락온 설정을 위한 DynamoDB Table 생성
# =============================================================
# terraform {
#     # 협업을 위한 상태 값 공유 저장소 설정
#     backend "s3" {
#         bucket = "std17-instructor-terraform-state-bucket"
#         key    = "TerraformState/Lab/module/terraform.tfstate"  #버킷내 저장경로
#         region = "ap-northeast-3"
#         dynamodb_table = "std17-study-terraform-lock-table"
#         encrypt = true
#     }
# }

resource "aws_dynamodb_table" "terraform_lock" {
    name = "std17-study-terraform-lock-table"
    # DynamoDB의 관리방식(비용과 연관된 설정)
    billing_mode = "PROVISIONED"    # PAY_PER_REQUEST

    hash_key = "LockID"

    read_capacity   = 20 # 초당 4KB 데이터 읽기(RCU) => 1RCU
    write_capacity = 20 # 초당 4KB 데이터 쓰기(WCU) => 1WCU

    attribute {
        name = "LockID" # 관계형 데이터베이스의 P/K와 같은 역할
        type = "S"      # S(String), N(Number), B(Binary)
    }

}