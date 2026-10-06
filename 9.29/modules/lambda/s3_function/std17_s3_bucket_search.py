import json, os, boto3
from botocore.exceptions import ClientError

s3_resource = boto3.resource('s3')

def lambda_handler(event, context):
    try:
        s3_resource.meta.client.head_bucket(Bucket='std17-eu-west-2-bucket')
        exists = True
    # 버킷이 존재하지 않거나(404 Not Found) 권한이 없는 경우(403 Forbidden) ClientError 예외가 발생
    except ClientError as e:
        exists = False
        error_code = e.response['Error']['Code']
        if error_code == '404':
            print("Bucket does not exist.")
        elif error_code == '403':
            print("Access denied to the bucket.")
        else:
            print(f"Unexpected error: {e}")
        return {
            "statusCode": 400,
            "body": json.dumps({
                "error": str(e)
            }, ensure_ascii=False)
        }

    # 버킷의 존재 유무 및 권한 확인 후 추가 실행문 작성(exists, error_code)