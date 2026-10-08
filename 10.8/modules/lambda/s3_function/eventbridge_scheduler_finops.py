import json, boto3
import logging # CloudWatch Logs에 출력을 위한 로깅 모듈(라이브러리)


# 1. Lambda 로깅을 위한 객체 생성 및 로그 출력 레벨 설정
logger = logging.getLogger() # 로깅 객체 생성
logger.setLevel(logging.INFO) # INFO(INFO, WARNING, ERROR) 이상의 로그를 CloudWatch에 기록

# 2. boto3 클라이언트 객체 생성
ec2_client = boto3.client("ec2")
rds_client = boto3.client("rds")

# 대상 태그 (EC2 / RDS 공통 → 전역으로 선언)
TARGET_TAG_KEY = "AutoSchedule"
TARGET_TAG_VALUE = "true"

def lambda_handler(event, context):
    # 3. event["action"]에 따른 설정
    # 스케줄러(또는 테스트)를 통해 전달 받은 action KEY의 값
    action = event["action"].lower() 
    if action not in ["start", "stop"]:
        logger.error(f"유효하지 않은 ACTION: {action}")
        return {'statusCode': 400, 'body': 'Invalid action'}

    # CloudWatch Logs에 대한 작업 시작 안내 기록
    logger.info(f"=== FinOps 작업 시작: {action.upper()} ===")

    manage_ec2(action) # EC2 인스턴스 제어 함수 실행
    manage_rds(action) # RDS 인스턴스 제어 함수 실행

    return {'statusCode': 200, 'body': f"{action} 작업 수행을 완료했습니다."}

# ##########################################################################
# EC2 인스턴스 제어
# 기본 구성: 검색 필터링 -> 리소스 선택 -> [리소스 고유값(id), ...] 
# -> 코드 제어(리소스 없을 경우) -> 리소스에 명령 실행
def manage_ec2(action):
    # 필터링 구성
    filters = [{"Name": f"tag:AutoSchedule", "Values": [TARGET_TAG_VALUE]}]

    # 태그 검색 조건을 만족하는 EC2 인스턴스의 정보 조회
    response = ec2_client.describe_instances(Filters=filters)

    instance_ids = []
    # describe_instances()응답 객체를 통해 반복하여 인스턴스의 ID 추출
    for reservation in response['Reservations']:
        for instance in reservation["Instances"]:
            instance_ids.append(instance['InstanceId'])

    # 인스턴스가 없을 경우 함수 종료
    if not instance_ids:
        logger.info("대상 인스턴스가 없습니다.")
        return 
    
    if action == "start":
        ec2_client.start_instances(InstanceIds=instance_ids) # 인스턴스 시작 API 호출
        logger.info(f"인스턴스 시작 명령 완료: {instance_ids}")
    else:
        ec2_client.stop_instances(InstanceIds=instance_ids) # 인스턴스 중지 API 호출
        logger.info(f"인스턴스 중지 명령 완료: {instance_ids}")

# ##########################################################################
# MYSQL RDS 인스턴스 제어

def manage_rds(action):
    response = rds_client.describe_db_instances()

    for db_instance in response["DBInstances"]:
        db_id = db_instance["DBInstanceIdentifier"]
        db_arn = db_instance["DBInstanceArn"]
        status = db_instance["DBInstanceStatus"]

        tags_response = rds_client.list_tags_for_resource(ResourceName=db_arn)
        tag_list = tags_response.get("TagList", [])

        # RDS 인스턴스들 중 태그의 Key=AutoSchedule,
        # Value=true가 있다면 is_target=true (any에 의해)
        is_target = any(
            t['Key'] == TARGET_TAG_KEY and t['Value'] == TARGET_TAG_VALUE
            for t in tag_list
        )

        # 대상 태그가 존재하는 DB 인스턴스에 대해서만 시작/중지 판단하여 수행
        if is_target:
            if action=="start" and status == "stopped":
                rds_client.start_db_instance(DBInstanceIdentifier=db_id)
                logger.info(f"RDS 시작 명령 완료: {db_id}")
            elif action == "stop" and status == "available":
                rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
                logger.info(f"RDS 중지 명령 완료: {db_id}")
            else:
                logger.info(f"RDS {db_id} 작업 스킵: {status}")