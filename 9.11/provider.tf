terraform {
    # # 협업을 위한 상태 값 공유 저장소 설정
    # backend "s3" {
    #     bucket = "std17-instructor-terraform-state-bucket"
    #     key    = "TerraformState/Lab/module/terraform.tfstate"  #버킷내 저장경로
    #     region = "ap-northeast-3"
    #     dynamodb_table = "std17-lab-lock-table"
    #     encrypt = true
    # }
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