resource "aws_dynamodb_table" "dynamodb-table" {
    name           = "${local.tag_header}member-dynamodb" # 리전내에 유일한 이름
    # 테이블의 비용 지불 방식 및 처리 성능 관리 모드
    billing_mode   = "PROVISIONED"
    read_capacity  = 20 # RCU(초당 4KB 데이터 1개 읽기) --> 1RCU
    write_capacity = 20 # WCU(초당 1KB 데이터 1개 읽기) --> 1WCU
    hash_key       = "UserId"   # Partition Key: RDS의 Primary Key역할 수행
    range_key      = "UserName" # Sort Key: 정렬 키
    stream_enabled   = true     # 변경사항에 대한 로깅 범위 정의: 글로벌 테이블에서는 필수 사항
    stream_view_type = "NEW_AND_OLD_IMAGES"

    attribute {
        name = "UserId"
        type = "S"
    }

    attribute {
        name = "UserName"
        type = "S"
    }

	# 데이터의 유효기간 정의: 애플리케이션에서 데이터 삽입할 때 함께 추가해야 합니다.
    ttl {
        attribute_name = "TimeToExist"
        enabled        = true           # 기능 활성화
    }
    
	# 태그
    tags = { Name = "${local.tag_header}member-dynamodb" }
}