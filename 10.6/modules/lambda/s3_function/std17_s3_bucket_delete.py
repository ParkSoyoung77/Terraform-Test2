import json, os, boto3, random
from botocore.exceptions import ClientError

s3 = boto3.resource('s3', region_name='eu-west-2')
def lambda_handler(event, context):
    bucket = s3.Bucket("std17-eu-west-2-bucket-4028")

    # bucket.objects.all(): 객체를 하나씩 반환
    # any(): True가 1개 이상이면 True (Bucket의 Object도 True로 인정)
    has_objects = any(bucket.objects.all()) # 버킷에 객체가 있는지 확인

    if has_objects:
        # 버킷 비우기
        bucket.object_versions.delete()

    # 버킷 삭제
    bucket.delete()