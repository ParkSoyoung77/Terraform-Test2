import json, os, boto3, random
from botocore.exceptions import ClientError

s3 = boto3.client('s3', region_name='eu-west-2')
def lambda_hendler(event, context):
    rand_num = f"{random.randint(0,9999):04d}"
    bucket_name = f"std17-eu-west-2-bucket-{rand_num}"

    region = 'eu-west-2'

    if region == 'us-east-1':
        s3.create_bucket(Bucket=bucket_name)
    else:
        # 버지니아(us-east-1)를 제외한 모든 리전에서 버킷 생성 시, 매개변수 지정
        s3.create_bucket(Bucket="", CreateBucketConfiguration={'LocationConstraint': region})

    print(f"Bucket '{bucket_name}' create in region '{region}'.")