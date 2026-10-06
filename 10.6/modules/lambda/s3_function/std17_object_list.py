import json, os, boto3, random
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    s3 = boto3.client('s3', region_name='eu-west-2')

    # 버킷 이름 변수 설정
    bucket_name = "std17-eu-west-2-bucket-test1006"

    # S3 버킷의 객체 목록 반환(조회)
    response = s3.list_objects_v2(Bucket=bucket_name, Delimiter='/')

    # 객체 키(파일명) 목록 추출(버킷이 비어있으면 Contents 키는 없음.)
    # 즉, response가 'Contents'라는 것은 객체가 존재한다는 것을 말함.
    file_list = []
    if "Contents" in response:
        file_list = [ obj["Key"] for obj in response["Contents"] if not obj["Key"].endswith("/")]

    # 폴더 리스트
    folder_list = []
    if "CommonPrefixes" in response:
        # CommonPrefixes에서 Prefix 키 값을 로드
        folder_list = [ prefix['Prefix'] for prefix in response['CommonPrefixes'] ]

    result = {
        "files": file_list,
        "folders": folder_list
    }
    return{
        'statusCode': 200,
        'body': result
    }
