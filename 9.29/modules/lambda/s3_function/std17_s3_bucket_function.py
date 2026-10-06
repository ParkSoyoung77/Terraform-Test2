import json, os, boto3
from botocore.exceptions import ClientError

# S3 전체 기능 사용: boto3.clinet('s3', [region_name='eu-west-2])
s3_client = boto3.client('s3', region_name='eu-west-2')

# S3 리소스 사용: resorce 객체를 사용하면 S3 버킷과 객체에 대한 더 높은 수준의 추상화 제공
# s3_resource = boto3.resource('s3', region_name='eu-west-2')

# 버킷 이름 출력하기
def lambda_handler(event, context):
        # AWS 계정에 존재하는 모든 S3 버킷의 목록 조회
        response = s3_client.list_buckets()
        bucket_names = [bucket['Name'] for bucket in response['Buckets']]
        # bucket_names = []
        # for bucket in response.get("Buckest",[]):
        #     bucket_names.append({"name": bucket["Name"]})


        for bucket in bucket_names:
            print(f"Bucket: {bucket}")

            return {
                "statusCode": 200,
                "body": json.dumps({
                    "count": len(bucket_names),
                    "buckets": bucket_names
                }, ensure_ascii=False)
            }
        # except ClientError as e:
        #     print(f"Error: {e}")
        #     error_code = e.response['Error']['Code']
        #     error_msg = e.response['Error']['Message']
