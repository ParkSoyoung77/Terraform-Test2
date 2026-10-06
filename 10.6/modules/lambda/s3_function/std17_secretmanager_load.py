import json, os, boto3, random
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    secrets = boto3.client("secretmanager", region_name="eu-west-2")

    # 보안 암호 로드(읽기)
    response = secrets.get_secret_value(SecretID="")