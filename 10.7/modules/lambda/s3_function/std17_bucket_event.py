import json, os, boto3, urllib.parse

def lambda_handler(event, context):
    s3_client = boto3.client("s3")

    # S3에 지정된 이벤트
    record = event["Records"][0]["s3"]
    bucket_name = record["bucket"]["name"]
    raw_key = record["object"]["key"]
    # url 코드값을 일반형으로 변경: urllib.parse.unquote_plus("변경할 문자열")
    object_key = urllib.parse.unquote_plus(raw_key)

    print(f"버킷: {bucket_name}, Key: {object_key}")