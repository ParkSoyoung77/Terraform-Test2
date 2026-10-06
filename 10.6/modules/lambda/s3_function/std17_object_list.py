import json, os, boto3, random
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    s3 = boto3.client('s3', region_name='eu-west-2')

    # 버킷 이름 변수 설정
    bucket_name = "std17-eu-west-2-bucket-test1006"

    # S3 버킷의 객체 목록 반환(조회)
    response = s3.list_objects_v2(Bucket=bucket_name)

    # 객체 키(파일명) 목록 추출(버킷이 비어있으면 Contents 키는 없음.)
    # 즉, response가 'Contents'라는 것은 객체가 존재한다는 것을 말함.
    result = []
    if "Contents" in response:
        result = [ obj["Key"] for obj in response["Contents"] if not obj["Key"].endswith("/")]

    result = {
        "files": file_list
    }
    return{
        'statusCode': 200,
        'body': result
    }
