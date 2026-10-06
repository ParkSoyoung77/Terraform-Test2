import json, os, boto3, random
from botocore.exceptions import ClientError

s3 = boto3.resource('s3', region_name='eu-west-2')
# def lambda_handler(event, context):
#     get_params = event.get('queryStringParameters') or {}
#     bucket_name = (
#         get_params.get('bucket_name')
#         or os.environ.get('bucket_name')
#         or "std17-eu-west-2-default-bucket"
#     )
#     bucket = s3.Bucket(bucket_name)

#     # bucket.objects
#     has_objects = any(bucket.objects.all()) # 버킷에 객체가 있는지 확인
#     if has_objects:
#         # 버킷 비우기
#         bucket.object_versions.delete()

#     # 버킷 삭제
#     bucket.delete()