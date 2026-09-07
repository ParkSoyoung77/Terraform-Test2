resource "aws_s3_bucket" "terraform_state" {
    bucket = "std17-instructor-terraform-state-bucket"

    lifecycle {
        prevent_destroy = true
    }

    tags={
        Name = "std17-ex-terraform-state-bucket"
    }
}

resource "aws_s3_bucket_versioing" "state_versioning" {
    bucket = aws_s3_buck.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# =========================================================
# 상태 잠금용 DynamoDB 테이블 생성
# =========================================================
resource "aws_dynamodb_table" "terraform_lock" {
    name = "std17-lab-lock-table"
    # DynamoDB의 관리방식(비용과 연관된 설정)
    billing_mode = "PROVISIONED"    #PAY_PER_REQUEST

    read_capcity   = 20 # 초당 4KB 데이터 읽기(RCU) => 1RCU
    write_capacity = 20 # 초당 4KB 데이터 쓰기(WCU) => 1WCU

    attribute {
        name = "LockID" # 관계형 데이터베이스의 P/K와 같은 역할
        type = "S"      # S(String), N(Number), B(Binary)
    }
}