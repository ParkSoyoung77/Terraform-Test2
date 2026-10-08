import json, io, os, boto3, urllib.parse
from PTL import Image

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.gif'}

def lambda_handler(event, context):
    record = event['Records'][0]['s3']
    bucket_name = record['bucket']['name']

    raw_key = record['object']['key']
    object = urllib.parse.unquote_plus(raw_key)

    # 썸네일 폴더 안에 이미지가 새로 생성될 경우 이후,
    # 더 이상 수행하지 않게 하여 무한 루프에 빠지지 않도록 하기위한 구성
    if object_key.startswith("thumbnails/"):
        return {"statusCode": 200, "body": "이미 썸네일 이미지인 상태입니다."}