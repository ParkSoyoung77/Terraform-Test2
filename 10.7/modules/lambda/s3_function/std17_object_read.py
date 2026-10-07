import json, os, boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3', region_name='eu-west-2')
def lambda_handler(event, context):
    headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Access-Control-Allow-Origin': '*',                    # 모든 도메인/URL에서의 접근 허용
        'Access-Control-Allow-Headers': 'Content-Type',        # 허용할 요청 헤더
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'   # 허용할 HTTP 메서드
    }

    s3_client = boto3.client("s3")

    # 버킷 이름과 객체 키를 이용한 객체(파일) 로드(읽기)
    bucket_name = ""
    dir_name = "/"
    file_name = ""
    if dir_name in ["Root", "ROOT", "root", "/", ""]:
        object_key = f"{file_name}"
    else:
        object_key = f"{dir_name}/{file_name}"

    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    file_content = response["Body"].read().decode("utf-8")

    return {
        "statusCode": 200,
        "headers": headers,
        "body": file_content
    }
